class User < ApplicationRecord
  ALLOWED_DOMAINS = %w[columbia.edu barnard.edu].freeze

  devise :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :replies, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :category_follows, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :messages, dependent: :destroy
  has_many :rsvps, dependent: :destroy
  has_many :rsvped_posts, through: :rsvps, source: :post

  def unread_conversations_count
    conversations.count { |conversation| conversation.unread_for?(self) }
  end

  def contacts
    chat_ids = Conversation.for_user(self)
                          .where(kind: "direct", post_id: nil)
                          .where(id: Message.select(:conversation_id))
                          .select("conversations.id")

    User.joins(:conversation_participants)
        .where(conversation_participants: { conversation_id: chat_ids })
        .where.not(id: id)
        .distinct
        .order(:name)
  end

  def followed_categories
    category_follows.pluck(:category)
  end

  def follows?(category)
    category_follows.exists?(category: category)
  end

  before_validation { self.email = email.to_s.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validate :email_must_be_university_address

  def self.from_omniauth(auth)
    user = find_or_initialize_by(email: auth.info.email.to_s.downcase)
    user.name  = auth.info.name
    user.save
    user
  end

  private

  def email_must_be_university_address
    domain = email.to_s.split("@").last.to_s
    allowed = ALLOWED_DOMAINS.any? { |d| domain == d || domain.end_with?(".#{d}") }
    errors.add(:email, "must be a Columbia or Barnard address") unless allowed
  end
end
