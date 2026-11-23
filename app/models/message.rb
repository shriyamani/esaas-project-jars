class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user
  has_many :notifications, as: :source, dependent: :destroy

  KINDS = %w[text joined left].freeze
  EVENT_TEXT = { "joined" => "joined the chat", "left" => "left the chat" }.freeze

  scope :texts, -> { where(kind: "text") }

  after_create :notify_participants, unless: :event?

  validates :kind, inclusion: { in: KINDS }
  validates :body, presence: true, length: { maximum: 2000 }
  validate :sender_must_be_participant, unless: :event?

  EDIT_WINDOW = 15.minutes

  before_update { self.edited_at = Time.current if will_save_change_to_body? }

  def self.record_event!(conversation, user, kind)
    conversation.messages.create!(
      user: user, kind: kind, body: "#{conversation.name_for(user)} #{EVENT_TEXT.fetch(kind)}"
    )
  end

  def event?
    kind != "text"
  end

  def editable_by?(user)
    !event? && user_id == user.id && created_at > EDIT_WINDOW.ago
  end

  def edited?
    edited_at.present?
  end

  def display_author
    conversation.name_for(user)
  end

  private

  def notify_participants
    Notification.for_message(self)
  end

  def sender_must_be_participant
    return if conversation.nil? || user.nil?

    errors.add(:user, "is not part of this conversation") unless conversation.participant?(user)
  end
end
