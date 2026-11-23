require "rails_helper"

RSpec.describe "Renaming group chats", type: :request do
  let(:author) { create(:user) }
  let(:joiner) { create(:user) }
  let(:post_record) { create(:post, user: author, spots_available: 2, title: "Uber to JFK") }
  let(:chat) { post_record.group_conversation }

  before do
    create(:post_membership, post: post_record, user: joiner)
    chat.conversation_participants.create!(user: joiner)
  end

  describe "as the post's author" do
    before { sign_in author }

    it "shows a rename (pencil) link and the rename form" do
      get conversation_path(chat)
      expect(response.body).to include('aria-label="Rename chat"')

      get conversation_path(chat, renaming: 1)
      expect(response.body).to include('name="conversation[name]"')
    end

    it "renames the chat and shows the new name to every member" do
      patch conversation_path(chat), params: { conversation: { name: "  JFK crew  " } }

      expect(response).to redirect_to(conversation_path(chat))
      expect(chat.reload.name).to eq("JFK crew")

      sign_in joiner
      get conversations_path
      expect(response.body).to include("JFK crew")
    end

    it "goes back to the post title when the name is cleared" do
      chat.update!(name: "JFK crew")

      patch conversation_path(chat), params: { conversation: { name: "" } }

      expect(chat.reload.name).to be_nil
      expect(chat.title_for(author)).to eq("Uber to JFK")
    end

    it "rejects names that are too long" do
      patch conversation_path(chat), params: { conversation: { name: "x" * 81 } }

      expect(chat.reload.name).to be_nil
      expect(flash[:alert]).to be_present
    end
  end

  describe "as a member who is not the author" do
    before { sign_in joiner }

    it "does not show the rename link" do
      get conversation_path(chat)
      expect(response.body).not_to include('aria-label="Rename chat"')
    end

    it "does not allow renaming" do
      patch conversation_path(chat), params: { conversation: { name: "Hijacked" } }

      expect(chat.reload.name).to be_nil
      expect(flash[:alert]).to eq("Only the post's author can rename this chat.")
    end
  end

  it "does not let a non-member rename the chat" do
    sign_in create(:user)

    patch conversation_path(chat), params: { conversation: { name: "Hijacked" } }

    expect(response).to have_http_status(:not_found)
    expect(chat.reload.name).to be_nil
  end

  it "does not allow renaming a direct chat" do
    other = create(:user)
    direct = Conversation.direct_between(author, other)
    sign_in author

    patch conversation_path(direct), params: { conversation: { name: "Buddies" } }

    expect(direct.reload.name).to be_nil
  end
end
