require "rails_helper"

RSpec.describe Rsvp, type: :model do
  let(:user) { create(:user) }
  let(:post) { create(:post) }

  describe "validations" do
    it "is valid with a user and post" do
      rsvp = build(:rsvp, user: user, post: post)
      expect(rsvp).to be_valid
    end

    it "enforces uniqueness of user scoped to post" do
      create(:rsvp, user: user, post: post)
      duplicate_rsvp = build(:rsvp, user: user, post: post)

      expect(duplicate_rsvp).not_to be_valid
      expect(duplicate_rsvp.errors[:user_id]).to include("has already RSVP'd to this event")
    end

    it "allows a user to RSVP to different posts" do
      other_post = create(:post)
      create(:rsvp, user: user, post: post)
      another_rsvp = build(:rsvp, user: user, post: other_post)

      expect(another_rsvp).to be_valid
    end

    it "allows multiple users to RSVP to the same post" do
      other_user = create(:user)
      create(:rsvp, user: user, post: post)
      another_rsvp = build(:rsvp, user: other_user, post: post)

      expect(another_rsvp).to be_valid
    end
  end
end

