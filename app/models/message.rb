class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }
  validate :sender_must_be_participant

  def display_author
    conversation.name_for(user)
  end

  private

  def sender_must_be_participant
    return if conversation.nil? || user.nil?

    errors.add(:user, "is not part of this conversation") unless conversation.participant?(user)
  end
end