require "rails_helper"

RSpec.describe "Conversations", type: :request do
  let(:me) { create(:user, name: "Me Myself", email: "me@columbia.edu") }
  let(:friend) { create(:user, name: "Friend Lion", email: "friend@barnard.edu") }
  let(:chat) { Conversation.direct_between(me, friend) }

  it "redirects to sign in when logged out" do
    get conversations_path
    expect(response).to redirect_to(new_user_session_path)
  end

  describe "when logged in" do
    before { sign_in me }

    describe "chats list" do
      it "says when there are no messages yet" do
        get conversations_path
        expect(response.body).to include("No messages yet.")
      end

      it "hides chats that have no messages" do
        chat
        get conversations_path
        expect(response.body).not_to include("Friend Lion")
      end

      it "shows each chat with its last message and marks unread ones" do
        create(:message, conversation: chat, user: friend, body: "Want to study later?")

        get conversations_path

        row = response.parsed_body.at_css("##{ActionView::RecordIdentifier.dom_id(chat)}")
        expect(row.text).to include("Friend Lion", "Want to study later?")
        expect(row["class"]).to include("is-unread")
      end

      it "prefixes my own last message with You:" do
        create(:message, conversation: chat, user: me, body: "See you there")
        get conversations_path
        expect(response.body).to include("You: See you there")
      end
    end

    describe "contacts tab" do
      it "lists people I have chatted with" do
        create(:message, conversation: chat, user: friend)

        get conversations_path(tab: "contacts")

        expect(response.body).to include("Friend Lion", "friend@barnard.edu")
        expect(response.parsed_body.at_css(".messages_tab[aria-current='page']").text).to eq("Contacts")
      end

      it "says when there are no contacts" do
        get conversations_path(tab: "contacts")
        expect(response.body).to include("No contacts yet.")
      end
    end

    describe "viewing a chat" do
      it "shows the messages and marks the chat as read" do
        create(:message, conversation: chat, user: friend, body: "Hi there")

        get conversation_path(chat)

        expect(response.body).to include("Friend Lion", "Hi there")
        expect(chat.unread_for?(me)).to be false
      end

      it "does not mark the chat as read for a Turbo prefetch" do
        create(:message, conversation: chat, user: friend)

        get conversation_path(chat), headers: { "X-Sec-Purpose" => "prefetch" }

        expect(chat.unread_for?(me)).to be true
      end

      it "shows Sent, then Seen once the other person reads my last message" do
        create(:message, conversation: chat, user: me)

        get conversation_path(chat)
        expect(response.parsed_body.at_css(".message_receipt").text.strip).to eq("Sent")

        chat.mark_read_by(friend)
        get conversation_path(chat)
        expect(response.parsed_body.at_css(".message_receipt").text.strip).to eq("Seen")
      end

      it "returns not found for a chat I am not in" do
        other_chat = Conversation.direct_between(friend, create(:user))

        get conversation_path(other_chat)

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "starting a chat" do
      it "opens a chat with the user who has that email" do
        friend
        post conversations_path, params: { email: "  FRIEND@barnard.edu " }

        expect(response).to redirect_to(conversation_path(Conversation.direct_between(me, friend)))
      end

      it "opens a chat from a user id and reuses an existing chat" do
        chat

        expect { post conversations_path, params: { user_id: friend.id } }.not_to change(Conversation, :count)
        expect(response).to redirect_to(conversation_path(chat))
      end

      it "asks for an email when none is given" do
        post conversations_path, params: { email: " " }

        expect(response).to redirect_to(new_conversation_path)
        expect(flash[:alert]).to eq("Enter an email address.")
      end

      it "keeps the email and explains when no account uses it" do
        post conversations_path, params: { email: "nobody@columbia.edu" }

        expect(response).to redirect_to(new_conversation_path(email: "nobody@columbia.edu"))
        expect(flash[:alert]).to eq("No LionDen account uses that email.")
      end

      it "does not let me message myself" do
        expect { post conversations_path, params: { email: me.email } }.not_to change(Conversation, :count)
        expect(flash[:alert]).to eq("You can't message yourself.")
      end

      it "prefills the new message form with the email" do
        get new_conversation_path(email: "nobody@columbia.edu")
        expect(response.parsed_body.at_css("input[name='email']")["value"]).to eq("nobody@columbia.edu")
      end
    end

    describe "navigation" do
      def messages_link
        response.parsed_body.at_css("a.nav_icon[aria-label='Messages']")
      end

      it "shows the unread chat count on the Messages icon" do
        get posts_path
        expect(messages_link.at_css(".nav_badge")).to be_nil

        create(:message, conversation: chat, user: friend)
        get posts_path
        expect(messages_link.at_css(".nav_badge").text).to include("1")
      end

      it "marks the Messages icon as current on the messages pages" do
        get conversations_path
        expect(messages_link["aria-current"]).to eq("page")
      end
    end

    describe "avatar menu" do
      def message_button
        response.parsed_body.at_css("button[aria-label='Message Friend Lion']")
      end

      it "offers to message the author from their post card, post page and reply" do
        post_record = create(:post, user: friend)

        get posts_path
        expect(message_button).to be_present

        create(:reply, post: post_record, user: friend, anonymous: false)
        post_record.update_column(:user_id, me.id)
        get post_path(post_record)
        expect(message_button).to be_present
      end

      it "does not offer to message anonymous authors or myself" do
        create(:post, user: friend, anonymous: true)
        create(:post, user: me)

        get posts_path

        expect(response.parsed_body.css(".avatar_menu")).to be_empty
      end
    end
  end
end
