require "rails_helper"

RSpec.describe Message, type: :model do
  let(:sender) { create(:user, name: "Sam Sender") }
  let(:message) { create(:message, user: sender) }

  describe "validations" do
    it "is valid when sent by a participant" do
      expect(message).to be_valid
    end

    it "requires a body of at most 2000 characters" do
      expect(build(:message, body: "")).not_to be_valid
      expect(build(:message, body: "a" * 2001)).not_to be_valid
    end

    it "rejects a sender who is not in the conversation" do
      outsider_message = build(:message, conversation: message.conversation, user: create(:user))

      expect(outsider_message).not_to be_valid
      expect(outsider_message.errors[:user]).to include("is not part of this conversation")
    end
  end

  describe "#editable_by?" do
    it "lets only the sender edit, and only within 15 minutes" do
      expect(message.editable_by?(sender)).to be true
      expect(message.editable_by?(create(:user))).to be false

      travel 16.minutes do
        expect(message.editable_by?(sender)).to be false
      end
    end
  end

  describe "editing" do
    it "marks the message edited only when the body changes" do
      expect(message).not_to be_edited

      message.touch
      expect(message.reload).not_to be_edited

      message.update!(body: "Fixed typo")
      expect(message.reload).to be_edited
    end
  end

  it "shows Anonymous for the author of an anonymous post's group chat" do
    post = create(:post, user: sender, anonymous: true)
    conversation = create(:conversation, kind: "group", post: post, participants: [ sender ])

    expect(create(:message, conversation: conversation, user: sender).display_author).to eq("Anonymous")
  end
end
