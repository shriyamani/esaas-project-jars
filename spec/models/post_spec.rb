require "rails_helper"

RSpec.describe Post, type: :model do
  let(:user) { create(:user, name: "Alice Roar") }

  describe "validations" do
    it "is valid with valid attributes" do
      post = build(:post, user: user)
      expect(post).to be_valid
    end

    it "requires a title" do
      post = build(:post, title: nil)
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("can't be blank")
    end

    it "requires a category" do
      post = build(:post, category: nil)
      expect(post).not_to be_valid
      expect(post.errors[:category]).to include("can't be blank")
    end

    it "rejects invalid categories" do
      post = build(:post, category: "InvalidCategory")
      expect(post).not_to be_valid
      expect(post.errors[:category]).to include("is not included in the list")
    end

    it "accepts all allowed categories" do
      Post::CATEGORIES.each do |cat|
        post = build(:post, category: cat)
        expect(post).to be_valid
      end
    end

    it "requires a user" do
      post = build(:post, user: nil)
      expect(post).not_to be_valid
      expect(post.errors[:user]).to be_present
    end

    it "requires expires_at" do
      post = build(:post, expires_at: nil, expiration_preset: nil)
      expect(post).not_to be_valid
      expect(post.errors[:expires_at]).to include("can't be blank")
    end

    it "rejects an expiration date in the past" do
      post = build(:post, expires_at: 1.hour.ago)
      expect(post).not_to be_valid
      expect(post.errors[:expires_at]).to include("must be in the future")
    end
  end

  describe "expiration preset conversion" do
    it "converts Tonight to the end of today" do
      post = build(:post, expires_at: nil, expiration_preset: "Tonight")
      post.valid?
      expect(post.expires_at).to be_within(2.seconds).of(Time.current.end_of_day)
    end

    it "converts This week to the end of this week" do
      post = build(:post, expires_at: nil, expiration_preset: "This week")
      post.valid?
      expect(post.expires_at).to be_within(2.seconds).of(Time.current.end_of_week)
    end

    it "converts Custom to the given custom date" do
      target_time = 5.days.from_now.change(usec: 0)
      post = build(:post, expires_at: nil, expiration_preset: "Custom", custom_expires_at: target_time.to_s)
      post.valid?
      expect(post.expires_at).to be_within(2.seconds).of(target_time)
    end

    it "saves the chosen preset and rejects unknown ones" do
      expect(create(:post, expiration_preset: "Tonight").reload.expiration_preset).to eq("Tonight")
      expect(build(:post, expiration_preset: "Next year")).not_to be_valid
    end

    it "keeps the expiration when a post is edited without changing its preset" do
      post = create(:post, expiration_preset: "This week")
      later = 2.days.from_now.change(usec: 0)
      post.update_column(:expires_at, later)

      post.update!(title: "New title")

      expect(post.reload.expires_at).to eq(later)
    end

    it "keeps the exact expiration when the same custom time is resubmitted" do
      post = create(:post, expires_at: 3.days.from_now.change(sec: 42, usec: 0))
      original = post.expires_at

      post.update!(expiration_preset: "Custom", custom_expires_at: original.strftime("%Y-%m-%dT%H:%M"))

      expect(post.reload.expires_at).to eq(original)
    end
  end

  describe "#display_author" do
    it "returns Anonymous when anonymous is true" do
      post = build(:post, user: user, anonymous: true)
      expect(post.display_author).to eq("Anonymous")
    end

    it "returns the user name when anonymous is false" do
      post = build(:post, user: user, anonymous: false)
      expect(post.display_author).to eq("Alice Roar")
    end
  end

  describe ".active" do
    it "returns only non-expired posts" do
      active_post = create(:post, expires_at: 2.days.from_now)
      expired_post = build(:post, expires_at: 2.days.ago)
      expired_post.save(validate: false)

      expect(Post.active).to include(active_post)
      expect(Post.active).not_to include(expired_post)
    end

    it "excludes posts once their expiration time passes" do
      start_time = Time.zone.local(2026, 11, 9, 12, 0, 0)
      post = nil

      travel_to start_time do
        post = create(:post, expires_at: 1.hour.from_now)
        expect(Post.active).to include(post)
      end

      travel_to start_time + 2.hours do
        expect(Post.active).not_to include(post)
      end
    end
  end

  describe ".search" do
    it "matches titles and bodies without case sensitivity and excludes expired posts" do
      title_match = create(:post, title: "Campus Orchestra", body: "Rehearsal tonight")
      body_match = create(:post, title: "Music meetup", body: "Bring your ORCHESTRA friends")
      create(:post, title: "Study group", body: "Meet in the library")
      expired_match = create(:post, title: "Orchestra archive")
      expired_match.update_column(:expires_at, 1.day.ago)

      expect(Post.search("  oRcHeStRa  ")).to contain_exactly(title_match, body_match)
    end

    it "treats SQL wildcard characters as literal text" do
      exact_match = create(:post, title: "100% ready")
      create(:post, title: "100 days ready")

      expect(Post.search("100%")).to eq([ exact_match ])
    end

    it "composes with a category filter and returns active posts for a blank query" do
      housing = create(:post, title: "Roommate", category: "Housing")
      create(:post, title: "Roommate", category: "Social")
      expired = create(:post, title: "Old roommate", category: "Housing")
      expired.update_column(:expires_at, 1.day.ago)

      expect(Post.where(category: "Housing").search("roommate")).to eq([ housing ])
      expect(Post.where(category: "Housing").search("  ")).to eq([ housing ])
    end
  end

  describe "time zone configuration" do
    it "uses Eastern Time" do
      expect(Time.zone.name).to eq("Eastern Time (US & Canada)")
    end
  end

  it "rejects 'All posts' as a category" do
    expect(build(:post, category: "All posts")).not_to be_valid
  end

  describe ".newest_first" do
    it "orders posts newest first" do
      older = create(:post, title: "Older")
      older.update_column(:created_at, 2.days.ago)
      newer = create(:post, title: "Newer")

      expect(Post.newest_first.to_a).to eq([ newer, older ])
    end
  end

  describe ".trending" do
    it "ranks posts by recent activity, with a reply worth two likes" do
      quiet = create(:post, title: "Quiet")
      liked = create(:post, title: "Liked")
      replied = create(:post, title: "Replied")
      create(:like, post: liked)
      create(:reply, post: replied)

      expect(Post.trending.to_a).to eq([ replied, liked, quiet ])
    end

    it "ignores likes and replies from the post's own author" do
      own_activity = create(:post, title: "Own activity")
      create(:like, post: own_activity, user: own_activity.user)
      create(:reply, post: own_activity, user: own_activity.user)
      liked_by_other = create(:post, title: "Liked by other")
      liked_by_other.update_column(:created_at, 1.day.ago)
      create(:like, post: liked_by_other)

      expect(Post.trending.first).to eq(liked_by_other)
    end

    it "ignores activity older than the trending window" do
      old_buzz = create(:post, title: "Old buzz")
      old_buzz.update_column(:created_at, 1.day.ago)
      create(:reply, post: old_buzz).update_column(:created_at, 3.days.ago)
      fresh = create(:post, title: "Fresh")

      expect(Post.trending.to_a).to eq([ fresh, old_buzz ])
    end

    it "breaks ties by showing the newest post first" do
      older = create(:post, title: "Older")
      older.update_column(:created_at, 2.days.ago)
      newer = create(:post, title: "Newer")

      expect(Post.trending.to_a).to eq([ newer, older ])
    end

    it "combines with the active scope and category filters" do
      housing = create(:post, category: "Housing")
      create(:post, category: "Social")

      expect(Post.active.where(category: "Housing").trending.to_a).to eq([ housing ])
    end
  end

  describe "#liked_by?" do
    it "is true only for users who liked the post" do
      post = create(:post)
      fan = create(:user)
      create(:like, post: post, user: fan)

      expect(post.liked_by?(fan)).to be true
      expect(post.liked_by?(create(:user))).to be false
    end
  end

  describe "event date validation" do
    let(:freeze_time) { Time.zone.local(2026, 11, 15, 12, 0, 0) }

    it "uses midnight when an event time cannot be parsed" do
      date = Date.new(2026, 11, 24)
      post = build(:post, event_date: date, event_time: "not a time")

      expect(post.start_time).to eq(Time.zone.local(2026, 11, 24))
    end

    it "uses local midnight when an event has no time" do
      post = build(:post, event_date: Date.new(2026, 11, 24), event_time: nil)

      expect(post.start_time).to eq(Time.zone.local(2026, 11, 24))
    end

    it "is valid when event date is before post expires" do
      travel_to freeze_time do
        post = build(:post, event_date: Date.tomorrow, expires_at: 3.days.from_now)
        expect(post).to be_valid
      end
    end

    it "is valid when event date is on the same day as expiration" do
      travel_to freeze_time do
        post = build(:post, event_date: Date.current + 2.days, expires_at: (Date.current + 2.days).end_of_day)
        expect(post).to be_valid
      end
    end

    it "rejects an event date after the post expires" do
      travel_to freeze_time do
        post = build(:post, event_date: Date.current + 5.days, expires_at: 2.days.from_now)
        expect(post).not_to be_valid
        expect(post.errors[:event_date]).to include("can't be after the post expires")
      end
    end

    it "rejects an event time after the post expires" do
      travel_to freeze_time do
        post = build(
          :post,
          event_date: Date.current + 2.days,
          event_time: "8:00 PM",
          expires_at: Time.zone.local(2026, 11, 17, 18, 0, 0)
        )
        expect(post).not_to be_valid
        expect(post.errors[:event_date]).to include("can't be after the post expires")
      end
    end
  end

  describe ".upcoming" do
    let(:freeze_time) { Time.zone.local(2026, 11, 15, 12, 0, 0) }

    it "includes future events and excludes past events and non-events" do
      travel_to freeze_time do
        future_event = create(:post, event_date: Date.current + 2.days, expires_at: 5.days.from_now)
        past_event = build(:post, event_date: Date.current - 2.days, expires_at: 5.days.from_now)
        past_event.save(validate: false)
        non_event = create(:post, event_date: nil, expires_at: 5.days.from_now)

        upcoming_posts = Post.upcoming
        expect(upcoming_posts).to include(future_event)
        expect(upcoming_posts).not_to include(past_event)
        expect(upcoming_posts).not_to include(non_event)
      end
    end

    it "drops events once their date has passed" do
      travel_to freeze_time do
        event = create(:post, event_date: Date.current + 1.day, expires_at: 5.days.from_now)
        expect(Post.upcoming).to include(event)

        travel 2.days
        expect(Post.upcoming).not_to include(event)
      end
    end
  end

  describe ".for_user" do
    let(:current_student) { create(:user) }
    let(:other_student) { create(:user) }

    it "returns posts created by the user" do
      authored_post = create(:post, user: current_student)
      other_post = create(:post, user: other_student)

      expect(Post.for_user(current_student)).to include(authored_post)
      expect(Post.for_user(current_student)).not_to include(other_post)
    end

    it "returns posts the user has RSVP'd to" do
      post_to_attend = create(:post, user: other_student)
      create(:rsvp, user: current_student, post: post_to_attend)

      unrelated_post = create(:post, user: other_student)

      user_posts = Post.for_user(current_student)
      expect(user_posts).to include(post_to_attend)
      expect(user_posts).not_to include(unrelated_post)
    end

    it "does not duplicate posts if the user authored and RSVP'd to them" do
      own_post = create(:post, user: current_student)
      create(:rsvp, user: current_student, post: own_post)

      expect(Post.for_user(current_student).where(id: own_post.id).count).to eq(1)
    end

    it "returns none when user is nil" do
      create(:post)
      expect(Post.for_user(nil)).to be_empty
    end
  end
end
