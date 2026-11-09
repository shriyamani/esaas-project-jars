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

  describe "time zone configuration" do
    it "uses Eastern Time" do
      expect(Time.zone.name).to eq("Eastern Time (US & Canada)")
    end
  end
end
