require "rails_helper"

RSpec.describe Conversation, type: :model do
  let(:alice) { create(:user, name: "Alice Roar") }
  let(:bob) { create(:user, name: "Bob Lion") }

  it "only allows direct or group kinds" do
    expect(build(:conversation, kind: "direct")).to be_valid
    expect(build(:conversation, kind: "broadcast")).not_to be_valid
  end

  describe ".direct_between" do
    it "creates a chat with both users the first time" do
      conversation = Conversation.direct_between(alice, bob)

      expect(conversation.kind).to eq("direct")
      expect(conversation.participants).to contain_exactly(alice, bob)
    end

    it "reuses the existing chat no matter who starts it" do
      first = Conversation.direct_between(alice, bob)

      expect(Conversation.direct_between(bob, alice)).to eq(first)
      expect(Conversation.count).to eq(1)
    end

    it "does not let a user message themselves" do
      expect { Conversation.direct_between(alice, alice) }.to raise_error(ArgumentError)
    end
  end

  describe ".for_user" do
    it "returns only conversations the user is in" do
      mine = Conversation.direct_between(alice, bob)
      Conversation.direct_between(bob, create(:user))

      expect(Conversation.for_user(alice)).to eq([ mine ])
    end
  end

  describe "#title_for" do
    it "shows the other person's name in a direct chat" do
      conversation = Conversation.direct_between(alice, bob)

      expect(conversation.title_for(alice)).to eq("Bob Lion")
      expect(conversation.title_for(bob)).to eq("Alice Roar")
    end

    it "shows the post title for a group chat and hides an anonymous author" do
      post = create(:post, user: alice, title: "Study group", anonymous: true)
      group = create(:conversation, kind: "group", post: post, participants: [ alice, bob ])

      expect(group.title_for(bob)).to eq("Study group")
      expect(group.name_for(alice)).to eq("Anonymous")
      expect(group.name_for(bob)).to eq("Bob Lion")
    end
  end

  describe "read tracking" do
    let(:conversation) { Conversation.direct_between(alice, bob) }

    it "is unread for the recipient until they read it, never for the sender" do
      create(:message, conversation: conversation, user: alice)

      expect(conversation.unread_for?(bob)).to be true
      expect(conversation.unread_for?(alice)).to be false

      conversation.mark_read_by(bob)
      expect(conversation.unread_for?(bob)).to be false
    end

    it "becomes unread again when a new message arrives" do
      conversation.mark_read_by(bob)

      travel 1.minute do
        create(:message, conversation: conversation, user: alice)
        expect(conversation.unread_for?(bob)).to be true
      end
    end

    it "is never unread for someone outside the conversation" do
      create(:message, conversation: conversation, user: alice)

      expect(conversation.unread_for?(create(:user))).to be false
    end

    it "lists who has seen a message, excluding the sender" do
      message = create(:message, conversation: conversation, user: alice)
      expect(conversation.seen_by(message)).to be_empty

      conversation.mark_read_by(alice)
      conversation.mark_read_by(bob)
      expect(conversation.seen_by(message)).to eq([ bob ])
    end
  end

  it "returns the most recent message as the last message" do
    conversation = Conversation.direct_between(alice, bob)
    create(:message, conversation: conversation, user: alice, body: "First")
    create(:message, conversation: conversation, user: bob, body: "Second")

    expect(conversation.last_message.body).to eq("Second")
  end
end
