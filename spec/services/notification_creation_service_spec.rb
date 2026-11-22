require "rails_helper"

RSpec.describe NotificationCreationService do
  let(:author) { create(:user) }
  let(:follower) { create(:user) }

  describe ".for_new_post" do
    it "notifies followers of the post's category once, excluding other users and the author" do
      post = create(:post, user: author, category: "Housing")
      create(:category_follow, user: follower, category: "Housing")
      create(:category_follow, user: author, category: "Housing")
      other = create(:user)
      create(:category_follow, user: other, category: "Academics")

      expect { described_class.for_new_post(post) }.to change(Notification, :count).by(1)
      expect(follower.notifications.sole).to have_attributes(kind: "new_post", actor: author, source: post)
      expect(author.notifications).to be_empty
      expect(other.notifications).to be_empty
      expect { described_class.for_new_post(post) }.not_to change(Notification, :count)
    end
  end

  describe ".for_reply" do
    it "notifies the post author once for another student's reply" do
      post = create(:post, user: author)
      reply = create(:reply, post: post, user: follower)
      Notification.where(source: reply).delete_all

      expect { described_class.for_reply(reply) }.to change(Notification, :count).by(1)
      expect(author.notifications.sole).to have_attributes(kind: "reply", actor: follower, source: reply)
      expect { described_class.for_reply(reply) }.not_to change(Notification, :count)
    end

    it "does not notify someone of their own reply" do
      post = create(:post, user: author)
      reply = create(:reply, post: post, user: author)

      expect { described_class.for_reply(reply) }.not_to change(Notification, :count)
    end
  end

  describe ".for_join" do
    it "notifies the post author once when someone joins" do
      post = create(:post, user: author)
      rsvp = create(:rsvp, post: post, user: follower)
      Notification.where(source: rsvp).delete_all

      expect { described_class.for_join(rsvp) }.to change(Notification, :count).by(1)
      expect(author.notifications.sole).to have_attributes(kind: "join", actor: follower, source: rsvp)
      expect { described_class.for_join(rsvp) }.not_to change(Notification, :count)
    end
  end

  describe ".for_message" do
    it "notifies the other participant once" do
      conversation = Conversation.direct_between(author, follower)
      message = create(:message, conversation: conversation, user: author)
      Notification.where(source: message).delete_all

      expect { described_class.for_message(message) }.to change(Notification, :count).by(1)
      expect(follower.notifications.sole).to have_attributes(kind: "message", actor: author, source: message)
      expect(author.notifications).to be_empty
      expect { described_class.for_message(message) }.not_to change(Notification, :count)
    end
  end
end
