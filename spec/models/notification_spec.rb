require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:author) { create(:user, name: "Post Author") }
  let(:other) { create(:user, name: "Other Student") }

  it "notifies followers about a new post once, excluding its author" do
    follower = create(:user)
    create(:category_follow, user: follower, category: "Housing")
    create(:category_follow, user: author, category: "Housing")

    post = create(:post, user: author, category: "Housing")

    notification = follower.notifications.sole
    expect(notification).to have_attributes(kind: "new_post", source: post, actor: author)
    expect(notification.summary).to eq("New post in Housing: #{post.title}")
    expect(notification.destination).to eq(post)
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

    notification = author.notifications.sole
    expect(notification).to have_attributes(kind: "join", source: rsvp)
    expect(notification.summary).to eq("Other Student joined your post: #{post.title}")
    expect(notification.destination).to eq(post)
    expect { described_class.for_join(rsvp) }.not_to change(described_class, :count)
  end

  it "notifies each other conversation participant about a new message" do
    conversation = Conversation.direct_between(author, other)
    message = create(:message, conversation: conversation, user: author)

    notification = other.notifications.sole
    expect(notification).to have_attributes(kind: "message", source: message, actor: author)
    expect(notification.summary).to include("New message in")
    expect(notification.destination).to eq(conversation)
    expect(author.notifications).to be_empty
    expect { described_class.for_message(message) }.not_to change(described_class, :count)
  end

  it "removes notifications when their source is deleted" do
    post = create(:post, user: author)
    create(:reply, post: post, user: other)

    expect { post.destroy! }.to change(described_class, :count).by(-1)
  end

  it "returns nil summary and destination when its source no longer exists" do
    post = create(:post, user: author, spots_available: 2)
    create(:post_membership, post: post, user: other)
    notification = author.notifications.find_by!(kind: "join")
    notification.update_columns(source_id: Post.maximum(:id) + 1) # simulate a source that no longer exists

    notification.reload
    expect(notification.summary).to be_nil
    expect(notification.destination).to be_nil
  end

  it "summarizes a leave notification and links to the post" do
    post = create(:post, user: author, spots_available: 2)
    create(:post_membership, post: post, user: other).destroy

    notification = author.notifications.find_by!(kind: "leave")
    expect(notification.summary).to eq("Other Student left your post: #{post.title}")
    expect(notification.destination).to eq(post)
  end
end
