require "rails_helper"

RSpec.describe "Messages", type: :request do
  let(:me) { create(:user, name: "Me Myself") }
  let(:friend) { create(:user, name: "Friend Lion") }
  let(:chat) { Conversation.direct_between(me, friend) }

  before { sign_in me }

  describe "sending" do
    it "adds my message and returns to the composer" do
      expect {
        post conversation_messages_path(chat), params: { message: { body: "Hello!" } }
      }.to change(chat.messages, :count).by(1)

      expect(chat.messages.last).to have_attributes(user: me, body: "Hello!")
      expect(response).to redirect_to(conversation_path(chat, anchor: "message_composer"))
    end

    it "explains when the message is blank" do
      post conversation_messages_path(chat), params: { message: { body: "" } }

      expect(response).to redirect_to(conversation_path(chat))
      expect(flash[:alert]).to eq("Body can't be blank")
    end

    it "cannot send to a chat I am not in" do
      other_chat = Conversation.direct_between(friend, create(:user))

      post conversation_messages_path(other_chat), params: { message: { body: "Sneaky" } }

      expect(response).to have_http_status(:not_found)
      expect(other_chat.messages).to be_empty
    end
  end

  describe "editing" do
    let!(:message) { create(:message, conversation: chat, user: me, body: "Helo") }

    it "shows the edit form for my recent message" do
      get conversation_path(chat, editing: message.id)
      expect(response.parsed_body.at_css(".message_edit_form textarea").text.strip).to eq("Helo")
    end

    it "updates my message and labels it Edited" do
      patch conversation_message_path(chat, message), params: { message: { body: "Hello" } }

      expect(message.reload.body).to eq("Hello")
      expect(response).to redirect_to(conversation_path(chat, anchor: "message_#{message.id}"))

      get conversation_path(chat)
      expect(response.body).to include("Edited")
    end

    it "does not allow edits after 15 minutes" do
      travel 16.minutes do
        patch conversation_message_path(chat, message), params: { message: { body: "Too late" } }

        expect(message.reload.body).to eq("Helo")
        expect(flash[:alert]).to eq("Messages can only be edited within 15 minutes of sending.")

        get conversation_path(chat)
        expect(response.parsed_body.at_css(".message_action")).to be_nil
      end
    end

    it "keeps the edit form open when the new body is blank" do
      patch conversation_message_path(chat, message), params: { message: { body: "" } }

      expect(message.reload.body).to eq("Helo")
      expect(response).to redirect_to(conversation_path(chat, editing: message.id))
    end

    it "cannot edit someone else's message" do
      theirs = create(:message, conversation: chat, user: friend, body: "Original")

      patch conversation_message_path(chat, theirs), params: { message: { body: "Changed" } }

      expect(response).to have_http_status(:not_found)
      expect(theirs.reload.body).to eq("Original")
    end
  end
end
