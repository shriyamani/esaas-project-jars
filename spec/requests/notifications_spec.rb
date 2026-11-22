require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:author) { create(:user) }
  let(:other) { create(:user) }
  let(:post_record) { create(:post, user: author) }
  let!(:reply) { create(:reply, post: post_record, user: other) }

  before { sign_in author }

  it "shows the unread count in the bell and renders the dropdown" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css(".notifications_trigger")["aria-label"]).to eq("Notifications, 1 unread")
    expect(response.parsed_body.at_css(".notifications_badge").text).to eq("1")
    expect(response.body).to include("replied to your post")
  end

  it "marks an owned notification read before opening its post" do
    notification = author.notifications.sole

    post open_notification_path(notification)

    expect(response).to redirect_to(post_path(post_record))
    expect(notification.reload.read_at).to be_present
  end

  it "does not let another user open a notification" do
    notification = author.notifications.sole
    sign_in other

    post open_notification_path(notification)

    expect(response).to have_http_status(:not_found)
    expect(notification.reload.read_at).to be_nil
  end

  it "marks all owned notifications read" do
    create(:reply, post: post_record, user: create(:user))

    patch mark_all_read_notifications_path

    expect(author.notifications.unread.count).to eq(0)
    expect(response).to redirect_to(notifications_path)
  end

  it "clears a message notification when its conversation is read" do
    conversation = Conversation.direct_between(author, other)
    message = create(:message, conversation: conversation, user: other)

    get conversation_path(conversation)

    expect(author.notifications.find_by!(source: message).read_at).to be_present
  end
end
