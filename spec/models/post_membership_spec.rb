
require "rails_helper"

RSpec.describe PostMembership, type: :model do
  let(:author) { create(:user) }
  let(:student) { create(:user) }
  let(:post) { create(:post, user: author, spots_available: 2) }

  describe "validations" do
    it "allows a student to join a post" do
      membership = build(:post_membership, post: post, user: student)

      expect(membership).to be_valid
    end

    it "does not allow the author to join their own post" do
      membership = build(:post_membership, post: post, user: author)

      expect(membership).not_to be_valid
    end

    it "does not allow a student to join the same post twice" do
      create(:post_membership, post: post, user: student)

      duplicate = build(:post_membership, post: post, user: student)

      expect(duplicate).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to a post and a user" do
      membership = create(:post_membership, post: post, user: student)

      expect(membership.post).to eq(post)
      expect(membership.user).to eq(student)
    end
  end

  describe "notifications" do
    it "notifies the post author when someone joins" do
      expect {
        create(:post_membership, post: post, user: student)
      }.to change {
        Notification.where(kind: "join", recipient: author).count
      }.by(1)
    end
  end
end
