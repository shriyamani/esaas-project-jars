require "rails_helper"

RSpec.describe ConversationParticipant, type: :model do
  it "allows a user to join a conversation only once" do
    participant = create(:conversation_participant)
    duplicate = build(:conversation_participant, conversation: participant.conversation, user: participant.user)

    expect(duplicate).not_to be_valid
  end
end
