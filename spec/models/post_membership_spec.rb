
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

  describe "join and leave notifications" do
    it "points the join notification at the post" do
      create(:post_membership, post: post, user: student)

      expect(author.notifications.sole).to have_attributes(kind: "join", actor: student, source: post)
    end

    it "keeps the join notification and adds a leave notification when someone leaves" do
      membership = create(:post_membership, post: post, user: student)

      membership.destroy

      expect(author.notifications.recent_first.map(&:kind)).to eq(%w[leave join])
      expect(author.notifications.map(&:summary)).to all(include(post.title))
    end

    it "records every join and leave when the same person rejoins" do
      create(:post_membership, post: post, user: student).destroy
      create(:post_membership, post: post, user: student)

      expect(author.notifications.order(:id).map(&:kind)).to eq(%w[join leave join])
    end

    it "records joins from different people separately" do
      create(:post_membership, post: post, user: student)
      create(:post_membership, post: post, user: create(:user))

      expect(author.notifications.where(kind: "join").count).to eq(2)
    end

    it "does not send leave notifications when the post itself is deleted" do
      create(:post_membership, post: post, user: student)

      expect { post.destroy }.to change { Notification.count }.to(0)
    end
  end
end
