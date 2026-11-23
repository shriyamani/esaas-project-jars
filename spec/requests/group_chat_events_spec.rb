require "rails_helper"

RSpec.describe "Group chat join/leave lines", type: :request do
  let(:author) { create(:user, name: "Author A") }
  let(:one) { create(:user, name: "Joiner One") }
  let(:two) { create(:user, name: "Joiner Two") }
  let(:post_record) { create(:post, user: author, spots_available: 2) }
  let(:chat) { post_record.group_conversation }

  def join(user)
    sign_in user
    post post_post_membership_path(post_record)
  end

  def leave(user)
    sign_in user
    delete post_post_membership_path(post_record)
  end

  it "adds a joined line for each joiner, but not for the author" do
    join(one)
    join(two)

    expect(chat.messages.order(:id).map { |m| [ m.kind, m.body ] }).to eq([
      [ "joined", "Joiner One joined the chat" ],
      [ "joined", "Joiner Two joined the chat" ]
    ])
  end

  it "adds a left line that the remaining members see" do
    join(one)
    join(two)
    leave(two)

    expect(chat.messages.order(:id).last).to have_attributes(kind: "left", body: "Joiner Two left the chat")

    sign_in one
    get conversation_path(chat)
    expect(response.body).to include("Joiner Two left the chat")
    expect(response.body).to include('class="chat_event"')
  end

  it "does not send notifications for join/leave lines" do
    join(one)
    join(two)
    leave(two)

    expect(Notification.where(kind: "message")).to be_empty
  end

  it "hides 'Say hi' once someone has joined" do
    join(one)
    get conversation_path(chat)

    expect(response.body).to include("Joiner One joined the chat")
    expect(response.body).not_to include("Say hi to start the conversation.")
  end

  it "keeps Seen receipts on the last real message, not on a join line" do
    join(one)
    sign_in one
    post conversation_messages_path(chat), params: { message: { body: "hello" } }
    join(two)

    sign_in one
    get conversation_path(chat)
    expect(response.body).to include("message_receipt")
  end

  it "does not let anyone edit a join/leave line" do
    join(one)
    event = chat.messages.find_by!(kind: "joined")

    patch conversation_message_path(chat, event), params: { message: { body: "hacked" } }

    expect(response).to have_http_status(:not_found)
    expect(event.reload.body).to eq("Joiner One joined the chat")
  end

  it "shows a left line without 'You:' in the inbox preview" do
    join(one)
    join(two)
    leave(two)

    sign_in one
    get conversations_path
    expect(response.body).to include("Joiner Two left the chat")
    expect(response.body).not_to include("You: Joiner Two left the chat")
  end

  it "records a new joined line when someone rejoins" do
    join(one)
    leave(one)
    join(one)

    expect(chat.messages.order(:id).map(&:kind)).to eq(%w[joined left joined])
  end
end
