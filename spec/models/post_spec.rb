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

    it "automatically sets expiration to event end time for time ranges" do
      tomorrow = Date.tomorrow
      post = build(:post, event_date: tomorrow, event_time: "9:00 PM - 10:00 PM", expires_at: nil, expiration_preset: nil)
      post.valid?
      expected_end = Time.zone.parse("#{tomorrow} 10:00 PM")
      expect(post.expires_at).to be_within(2.seconds).of(expected_end)
    end

    it "automatically sets expiration to event end time for short time ranges" do
      tomorrow = Date.tomorrow
      post = build(:post, event_date: tomorrow, event_time: "9-10pm", expires_at: nil, expiration_preset: nil)
      post.valid?
      expected_end = Time.zone.parse("#{tomorrow} 10pm")
      expect(post.expires_at).to be_within(2.seconds).of(expected_end)
    end

    it "automatically sets expiration to single event time when no range is given" do
      tomorrow = Date.tomorrow
      post = build(:post, event_date: tomorrow, event_time: "5:00 PM", expires_at: nil, expiration_preset: nil)
      post.valid?
      expected_time = Time.zone.parse("#{tomorrow} 5:00 PM")
      expect(post.expires_at).to be_within(2.seconds).of(expected_time)
    end
  end

  describe "event start/end time fields" do
    it "combines start and end time inputs into a range" do
      post = build(:post, event_date: Date.tomorrow, event_start_time: "21:00", event_end_time: "22:30")
      post.valid?
      expect(post.event_time).to eq("9:00 PM - 10:30 PM")
    end

    it "stores a single time when only a start time is given" do
      post = build(:post, event_date: Date.tomorrow, event_start_time: "09:15", event_end_time: "")
      post.valid?
      expect(post.event_time).to eq("9:15 AM")
    end

    it "clears the event time when both inputs are blank" do
      post = build(:post, event_date: Date.tomorrow, event_time: "5:00 PM", event_start_time: "", event_end_time: "")
      post.valid?
      expect(post.event_time).to be_nil
    end

    it "requires a start time when an end time is given" do
      post = build(:post, event_date: Date.tomorrow, event_start_time: "", event_end_time: "22:00")
      expect(post).not_to be_valid
      expect(post.errors[:event_start_time]).to include("is required when an end time is set")
    end

    it "reads start and end inputs back from a stored range" do
      post = build(:post, event_time: "9:00 PM - 10:30 PM")
      expect(post.event_start_time).to eq("21:00")
      expect(post.event_end_time).to eq("22:30")
    end

    it "reads a single stored time as a start time with no end" do
      post = build(:post, event_time: "5:00 PM")
      expect(post.event_start_time).to eq("17:00")
      expect(post.event_end_time).to be_nil
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


  describe "post capacity" do
    let(:author) { create(:user) }
    let(:student1) { create(:user) }
    let(:student2) { create(:user) }
    let(:post) { create(:post, user: author, spots_available: 2) }

    describe "spots_available validation" do
      it "allows posts without a capacity" do
        post.spots_available = nil

        expect(post).to be_valid
      end

      it "rejects zero spots" do
        post.spots_available = 0

        expect(post).not_to be_valid
      end

      it "rejects negative spots" do
        post.spots_available = -1

        expect(post).not_to be_valid
      end

      it "rejects non-integer spots" do
        post.spots_available = 1.5

        expect(post).not_to be_valid
      end

      it "does not allow reducing capacity below the number of joined students" do
        create(:post_membership, post: post, user: student1)
        create(:post_membership, post: post, user: student2)

        post.spots_available = 1

        expect(post).not_to be_valid
      end

      it "does not allow clearing spots after someone has joined" do
        create(:post_membership, post: post, user: student1)

        post.spots_available = nil

        expect(post).not_to be_valid
        expect(post.errors[:spots_available]).to include("can't be removed after people have joined")
      end

      it "allows clearing spots again once everyone has left" do
        create(:post_membership, post: post, user: student1).destroy!

        post.spots_available = nil

        expect(post).to be_valid
      end
    end

    describe "capacity methods" do
      it "starts with zero filled spots" do
        expect(post.spots_filled).to eq(0)
      end

      it "counts joined students" do
        create(:post_membership, post: post, user: student1)

        expect(post.spots_filled).to eq(1)
        expect(post.spots_left).to eq(1)
      end

      it "recognizes when a post is full" do
        create(:post_membership, post: post, user: student1)
        create(:post_membership, post: post, user: student2)

        expect(post.full?).to be true
        expect(post.spots_left).to eq(0)
      end

      it "recognizes when a post is not full" do
        create(:post_membership, post: post, user: student1)

        expect(post.full?).to be false
      end

      it "tracks whether a student joined" do
        create(:post_membership, post: post, user: student1)

        expect(post.joined_by?(student1)).to be true
        expect(post.joined_by?(student2)).to be false
      end

      it "frees a spot when a student leaves" do
        membership = create(:post_membership, post: post, user: student1)
        membership.destroy!

        expect(post.spots_filled).to eq(0)
        expect(post.spots_left).to eq(2)
      end

      it "does not consider posts without a capacity full" do
        post.update!(spots_available: nil)

        expect(post.full?).to be false
        expect(post.spots_left).to be_nil
      end
    end
  end


  describe "group conversation" do
    let(:author) { create(:user) }

    it "creates a group chat with the author when a post has spots" do
      post = create(:post, user: author, spots_available: 3)

      conversation = post.group_conversation
      expect(conversation).to be_present
      expect(conversation.participants).to contain_exactly(author)
    end

    it "does not create a group chat for a post without spots" do
      post = create(:post, user: author, spots_available: nil)

      expect(post.group_conversation).to be_nil
    end

    it "creates the group chat when spots are added by editing the post" do
      post = create(:post, user: author, spots_available: nil)

      post.update!(spots_available: 2)

      expect(post.group_conversation.participants).to contain_exactly(author)
    end

    it "keeps a single group chat across later edits" do
      post = create(:post, user: author, spots_available: 2)

      expect { post.update!(title: "New title", spots_available: 4) }
        .not_to change(Conversation, :count)
    end

    it "adds joiners to the same chat the author already has" do
      post = create(:post, user: author, spots_available: 2)
      original = post.group_conversation
      joiner = create(:user)

      Post.transaction do
        post.post_memberships.create!(user: joiner)
        post.conversations.find_or_create_by!(kind: "group")
            .conversation_participants.find_or_create_by!(user: joiner)
      end

      expect(post.reload.group_conversation).to eq(original)
      expect(original.participants).to contain_exactly(author, joiner)
    end
  end
end
