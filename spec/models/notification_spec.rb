require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:author) { create(:user, name: "Post Author") }
  let(:other) { create(:user, name: "Other Student") }

  it "notifies followers about a new post once, excluding its author" do
    follower = create(:user)
    create(:category_follow, user: follower, category: "Housing")
    create(:category_follow, user: author, category: "Housing")

    post = create(:post, user: author, category: "Housing")

    expect(follower.notifications.sole).to have_attributes(kind: "new_post", source: post, actor: author)
    expect(author.notifications).to be_empty
    expect { described_class.for_new_post(post) }.not_to change(described_class, :count)
  end

  it "notifies a post author of another user's reply without exposing an anonymous reply author" do
    post = create(:post, user: author)
    reply = create(:reply, post: post, user: other, anonymous: true)

    expect(author.notifications.sole).to have_attributes(kind: "reply", source: reply)
    expect(author.notifications.sole.summary).to eq("Someone replied to your post: #{post.title}")
    expect { described_class.for_reply(reply) }.not_to change(described_class, :count)

    create(:reply, post: post, user: author)
    expect(author.notifications.count).to eq(1)
  end

  it "notifies the author when someone joins a post" do
    post = create(:post, user: author)
    rsvp = create(:rsvp, post: post, user: other)

    expect(author.notifications.sole).to have_attributes(kind: "join", source: rsvp)
    expect { described_class.for_join(rsvp) }.not_to change(described_class, :count)
  end

  it "notifies each other conversation participant about a new message" do
    conversation = Conversation.direct_between(author, other)
    message = create(:message, conversation: conversation, user: author)

    expect(other.notifications.sole).to have_attributes(kind: "message", source: message, actor: author)
    expect(author.notifications).to be_empty
    expect { described_class.for_message(message) }.not_to change(described_class, :count)
  end

  it "removes notifications when their source is deleted" do
    post = create(:post, user: author)
    create(:reply, post: post, user: other)

    expect { post.destroy! }.to change(described_class, :count).by(-1)
  end
end
