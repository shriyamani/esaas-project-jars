class Conversation < ApplicationRecord
  KINDS = %w[direct group].freeze

  belongs_to :post, optional: true
  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :messages, dependent: :destroy

  validates :kind, inclusion: { in: KINDS }

  scope :for_user, ->(user) {
    joins(:conversation_participants).where(conversation_participants: { user_id: user.id })
  }

  def self.direct_between(user_a, user_b)
    raise ArgumentError, "You can't message yourself" if user_a.id == user_b.id

    existing = where(kind: "direct", post_id: nil)
                 .joins(:conversation_participants)
                 .where(conversation_participants: { user_id: [ user_a.id, user_b.id ] })
                 .group(:id).having("COUNT(*) = 2").first
    return existing if existing

    transaction do
      conversation = create!(kind: "direct")
      conversation.participants << [ user_a, user_b ]
      conversation
    end
  end

  def group?
    kind == "group"
  end

  def participant?(user)
    conversation_participants.exists?(user_id: user.id)
  end

  def other_participants(user)
    participants.reject { |participant| participant.id == user.id }
  end

  def name_for(user)
    post&.anonymous? && user.id == post.user_id ? "Anonymous" : user.name
  end

  def title_for(viewer)
    return post&.title || "Group chat" if group?

    other = other_participants(viewer).first
    other ? name_for(other) : "Conversation"
  end

  def last_message
    messages.order(:created_at, :id).last
  end

  def unread_for?(user)
    participant = conversation_participants.find_by(user_id: user.id)
    return false unless participant

    unread = messages.where.not(user_id: user.id)
    unread = unread.where("messages.created_at > ?", participant.last_read_at) if participant.last_read_at
    unread.exists?
  end

  def mark_read_by(user)
    conversation_participants.where(user_id: user.id).update_all(last_read_at: Time.current)
  end

  def seen_by(message)
    conversation_participants.includes(:user)
                            .where.not(user_id: message.user_id)
                            .where("last_read_at >= ?", message.created_at)
                            .map(&:user)
  end
end