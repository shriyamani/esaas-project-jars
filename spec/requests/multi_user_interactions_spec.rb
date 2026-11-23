require "rails_helper"

RSpec.describe "Multi-user interactions", type: :request do
  let(:alice) { create(:user, name: "Alice Arthur", email: "alice@columbia.edu") }
  let(:bob) { create(:user, name: "Bob Bowman", email: "bob@barnard.edu") }
  let(:carol) { create(:user, name: "Carol Chen", email: "carol@columbia.edu") }
  let(:ride) { create(:post, user: alice, title: "Uber to JFK", spots_available: 2) }

  def as(user)
    sign_in user
    yield
  end

  def join(user, post_record = ride)
    as(user) { post post_post_membership_path(post_record) }
  end

  def leave(user, post_record = ride)
    as(user) { delete post_post_membership_path(post_record) }
  end

  def send_message(user, conversation, body)
    as(user) { post conversation_messages_path(conversation), params: { message: { body: body } } }
  end

  describe "joining a post" do
    it "shows the new spot count to a student who has not joined" do
      join(bob)

      as(carol) { get post_path(ride) }

      expect(response.body).to include("1 of 2 spots filled")
      expect(response.body).to include(">Join<")
    end

    it "does not show the group chat link to a student who has not joined" do
      join(bob)

      as(carol) { get post_path(ride) }

      expect(response.body).not_to include("Open group chat")
    end

    it "shows the group chat link to the author and the joiner" do
      join(bob)

      as(alice) { get post_path(ride) }
      expect(response.body).to include("Open group chat")

      as(bob) { get post_path(ride) }
      expect(response.body).to include("Open group chat")
    end

    it "notifies only the author, not other members or the joiner" do
      join(bob)
      join(carol)

      expect(alice.notifications.where(kind: "join").map(&:actor)).to contain_exactly(bob, carol)
      expect(bob.notifications.where(kind: "join")).to be_empty
      expect(carol.notifications.where(kind: "join")).to be_empty
    end

    it "does not notify the author when a join is rejected because the post is full" do
      ride.update!(spots_available: 1)
      join(bob)

      expect { join(carol) }.not_to change { alice.notifications.count }
      expect(ride.reload.spots_filled).to eq(1)
    end
  end

  describe "group chats" do
    let(:chat) { ride.group_conversation }

    before do
      join(bob)
      join(carol)
    end

    it "notifies every other member, including the author, of a new message" do
      send_message(bob, chat, "Meet at the gates?")

      expect(Notification.where(kind: "message").map(&:recipient)).to contain_exactly(alice, carol)
    end

    it "shows the message to another member, attributed to the sender" do
      send_message(bob, chat, "Meet at the gates?")

      as(carol) { get conversation_path(chat) }

      expect(response.body).to include("Meet at the gates?")
      expect(response.body).to include("Bob Bowman")
    end

    it "stops notifying a member after they leave" do
      leave(carol)
      send_message(bob, chat, "Carol left, still on?")

      expect(carol.notifications.where(kind: "message")).to be_empty
      expect(alice.notifications.where(kind: "message").count).to eq(1)
    end

    it "removes the chat from the list of a member who left, but not from others" do
      leave(carol)

      as(carol) { get conversations_path }
      expect(response.body).not_to include("Uber to JFK")

      as(bob) { get conversations_path }
      expect(response.body).to include("Uber to JFK")
    end

    it "marks the chat unread for other members but not the sender" do
      as(bob) { get conversation_path(chat) }
      send_message(bob, chat, "Running late")

      expect(chat.unread_for?(carol)).to be true
      expect(chat.unread_for?(alice)).to be true
      expect(chat.unread_for?(bob)).to be false

      as(carol) { get conversation_path(chat) }

      expect(chat.unread_for?(carol)).to be false
      expect(chat.unread_for?(alice)).to be true
    end

    it "shows the sender a receipt naming only the members who have read it" do
      send_message(bob, chat, "Running late")
      as(carol) { get conversation_path(chat) }

      as(bob) { get conversation_path(chat) }

      expect(response.body).to include("Seen by Carol Chen")
      expect(response.body).not_to include("Seen by Alice Arthur")
    end

    it "shows the author's new chat name to members" do
      as(alice) { patch conversation_path(chat), params: { conversation: { name: "JFK Crew" } } }

      as(bob) { get conversations_path }

      expect(response.body).to include("JFK Crew")
    end

    it "shows an anonymous author as Anonymous to members" do
      ride.update!(anonymous: true)
      send_message(alice, chat, "Booking the car now")

      as(bob) { get conversation_path(chat) }

      expect(response.body).to include("Booking the car now")
      expect(response.body).to include("Anonymous")
      expect(response.body).not_to include("Alice Arthur")
    end
  end

  describe "replies" do
    it "notifies the author with the replier's name" do
      as(bob) { post post_replies_path(ride), params: { reply: { body: "Leave at 5?" } } }

      as(alice) { get notifications_path }

      expect(response.body).to include("Bob Bowman replied to your post: Uber to JFK")
    end

    it "hides an anonymous replier's name from the author and other students" do
      as(bob) { post post_replies_path(ride), params: { reply: { body: "Split evenly?", anonymous: "1" } } }

      as(alice) { get notifications_path }
      expect(response.body).to include("Someone replied to your post: Uber to JFK")
      expect(response.body).not_to include("Bob Bowman")

      as(carol) { get post_path(ride) }
      expect(response.body).to include("Split evenly?")
      expect(response.body).not_to include("Bob Bowman")
    end

    it "does not notify other students who replied to the same post" do
      as(carol) { post post_replies_path(ride), params: { reply: { body: "I'm in" } } }
      as(bob) { post post_replies_path(ride), params: { reply: { body: "Me too" } } }

      expect(carol.notifications.where(kind: "reply")).to be_empty
      expect(alice.notifications.where(kind: "reply").count).to eq(2)
    end
  end

  describe "likes and RSVPs" do
    it "counts another student's like without marking the post liked for me" do
      as(bob) { post post_like_path(ride) }

      as(carol) { get posts_path }

      expect(response.body).to include('aria-label="Like Uber to JFK"')
      expect(response.body).not_to include('aria-label="Unlike Uber to JFK"')
      expect(ride.likes.count).to eq(1)
    end

    it "updates the organizer's attendee count as students RSVP and cancel" do
      event = create(:post, user: alice, title: "Board Game Night", category: "Social",
                            event_date: Date.tomorrow, event_time: "7:00 PM", location: "Lerner Hall")

      as(bob) { post post_rsvp_path(event) }
      as(carol) { post post_rsvp_path(event) }
      as(alice) { get post_path(event) }
      expect(response.body).to include('<span class="attendee-count">2</span>')

      as(bob) { delete post_rsvp_path(event) }
      as(alice) { get post_path(event) }
      expect(response.body).to include('<span class="attendee-count">1</span>')
    end
  end
end
