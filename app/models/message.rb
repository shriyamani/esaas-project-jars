class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 2000 }
  validate :sender_must_be_participant

  EDIT_WINDOW = 15.minutes

  before_update { self.edited_at = Time.current if will_save_change_to_body? }

  def editable_by?(user)
    user_id == user.id && created_at > EDIT_WINDOW.ago
  end

  def edited?
    edited_at.present?
  end

  def display_author
    conversation.name_for(user)
  end

  private

  def sender_must_be_participant
    return if conversation.nil? || user.nil?

    errors.add(:user, "is not part of this conversation") unless conversation.participant?(user)
  end
end