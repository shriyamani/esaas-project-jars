
require "rails_helper"

RSpec.describe "Post memberships", type: :request do
  let(:author) { create(:user) }
  let(:student) { create(:user) }
  let(:other_student) { create(:user) }
  let(:post_record) { create(:post, user: author, spots_available: 2) }

  describe "POST /posts/:post_id/post_membership" do
    before { sign_in student }

    it "does not allow another student to take the last spot" do
        post_record.update!(spots_available: 1)

        post post_post_membership_path(post_record)

        expect(post_record.spots_left).to eq(0)

        sign_in other_student

        expect {
            post post_post_membership_path(post_record)
        }.not_to change(PostMembership, :count)

        expect(post_record.reload.full?).to be true
        expect(post_record.spots_filled).to eq(1)
    end

    it "allows a student to join a post" do
      expect {
        post post_post_membership_path(post_record)
      }.to change(PostMembership, :count).by(1)

      expect(response).to redirect_to(conversation_path(Conversation.last))
      expect(post_record.joined_by?(student)).to be true
    end

    it "creates a group conversation with the author and student" do
      post post_post_membership_path(post_record)

      conversation = post_record.conversations.find_by(kind: "group")

      expect(conversation).to be_present
      expect(conversation.participants).to include(author, student)
      expect(conversation.participants.count).to eq(2)
    end

    it "reuses the existing group conversation for another student" do
      post post_post_membership_path(post_record)

      conversation = post_record.conversations.find_by!(kind: "group")

      sign_in other_student

      expect {
        post post_post_membership_path(post_record)
      }.not_to change(Conversation, :count)

      expect(conversation.reload.participants).to include(
        author, student, other_student
      )
    end

    it "does not allow duplicate joins" do
      post post_post_membership_path(post_record)

      expect {
        post post_post_membership_path(post_record)
      }.not_to change(PostMembership, :count)
    end

    it "does not allow joining a full post" do
      create(:post_membership, post: post_record, user: student)
      create(:post_membership, post: post_record, user: other_student)

      new_student = create(:user)
      sign_in new_student

      expect {
        post post_post_membership_path(post_record)
      }.not_to change(PostMembership, :count)

      expect(response).to redirect_to(post_path(post_record))
    end

    it "does not allow joining an expired post" do
      post_record.update_column(:expires_at, 1.hour.ago)

      expect {
        post post_post_membership_path(post_record)
      }.not_to change(PostMembership, :count)
    end

    it "does not allow joining a post without spots" do
      post_record.update!(spots_available: nil)

      expect {
        post post_post_membership_path(post_record)
      }.not_to change(PostMembership, :count)
    end

    it "does not allow the author to join their own post" do
      sign_in author

      expect {
        post post_post_membership_path(post_record)
      }.not_to change(PostMembership, :count)
    end
  end

  describe "DELETE /posts/:post_id/post_membership" do
    before do
      sign_in student
      post post_post_membership_path(post_record)
    end

    it "allows a student to leave and frees their spot" do
      expect {
        delete post_post_membership_path(post_record)
      }.to change(PostMembership, :count).by(-1)

      expect(post_record.spots_left).to eq(2)
    end

    it "removes the student from the group conversation" do
      conversation = post_record.conversations.find_by!(kind: "group")

      delete post_post_membership_path(post_record)

      expect(conversation.reload.participant?(student)).to be false
      expect(conversation.participant?(author)).to be true
    end

    it "does not delete the group conversation when someone leaves" do
      expect {
        delete post_post_membership_path(post_record)
      }.not_to change(Conversation, :count)
    end

    it "does not allow a former participant to view the group chat" do
      conversation = post_record.conversations.find_by!(kind: "group")

      delete post_post_membership_path(post_record)

      get conversation_path(conversation)

      expect(response).to have_http_status(:not_found)
    end
  end
end
