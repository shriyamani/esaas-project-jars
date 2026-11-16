class Post < ApplicationRecord
  CATEGORIES = ["Social", "Academics", "Housing", "Buy/Sell", "Travel", "Help" ].freeze
  EXPIRATION_PRESETS = [ "Tonight", "This week", "Custom" ].freeze
  TRENDING_WINDOW = 48.hours
  TRENDING_LIKE_WEIGHT = 1
  TRENDING_REPLY_WEIGHT = 2

  attr_accessor :expiration_preset, :custom_expires_at

  has_many :replies, dependent: :destroy
  has_many :likes, dependent: :destroy

  belongs_to :user

  before_validation :apply_expiration_preset

  validates :title, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :expires_at, presence: true
  validate :expires_at_must_be_in_the_future, if: -> { expires_at.present? && expires_at_changed? }

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :trending, -> {
    since = TRENDING_WINDOW.ago
    recent_likes = Like.where("likes.post_id = posts.id")
                      .where("likes.user_id <> posts.user_id")
                      .where("likes.created_at > ?", since)
                      .select("COUNT(*)").to_sql
    recent_replies = Reply.where("replies.post_id = posts.id")
                          .where("replies.user_id <> posts.user_id")
                          .where("replies.created_at > ?", since)
                          .select("COUNT(*)").to_sql

    order(
      Arel.sql("(#{TRENDING_LIKE_WEIGHT} * (#{recent_likes}) + #{TRENDING_REPLY_WEIGHT} * (#{recent_replies})) DESC"),
      created_at: :desc, id: :desc
    )
  }

  def display_author
    anonymous? ? "Anonymous" : user&.name
  end

  def liked_by?(user)
    likes.any? { |like| like.user_id == user.id }
  end

  private

  def expires_at_must_be_in_the_future
    errors.add(:expires_at, "must be in the future") if expires_at <= Time.current
  end

  def apply_expiration_preset
    case expiration_preset
    when "Tonight"
      self.expires_at = Time.current.end_of_day
    when "This week"
      self.expires_at = Time.current.end_of_week
    when "Custom"
      if custom_expires_at.present?
        parsed = custom_expires_at.respond_to?(:in_time_zone) ? custom_expires_at.in_time_zone : Time.zone.parse(custom_expires_at.to_s)
        self.expires_at = parsed if parsed
      end
    end
  end
end
