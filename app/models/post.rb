class Post < ApplicationRecord
  CATEGORIES = [ "Social", "Academics", "Housing", "Buy/Sell", "Travel", "Help" ].freeze
  EXPIRATION_PRESETS = [ "Tonight", "This week", "Custom" ].freeze
  TRENDING_WINDOW = 48.hours
  TRENDING_LIKE_WEIGHT = 1
  TRENDING_REPLY_WEIGHT = 2

  attr_accessor :custom_expires_at
  attr_writer :event_start_time, :event_end_time

  alias_attribute :date, :event_date
  alias_attribute :time, :event_time

  has_many :replies, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :rsvps, dependent: :destroy
  has_many :attendees, through: :rsvps, source: :user
  has_many :notifications, as: :source, dependent: :destroy

  belongs_to :user

  before_validation :compose_event_time
  before_validation :apply_expiration_preset
  after_create :notify_followers

  validates :title, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :expires_at, presence: true
  validate :expires_at_must_be_in_the_future, if: -> { expires_at.present? && expires_at_changed? }
  validates :expiration_preset, inclusion: { in: EXPIRATION_PRESETS }, allow_nil: true
  validate :event_end_time_requires_start_time
  validate :event_date_cannot_be_after_expires_at, if: -> { event_date.present? && expires_at.present? }

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :search, ->(query) {
    keyword = query.to_s.strip.downcase
    if keyword.blank?
      active
    else
      pattern = "%#{sanitize_sql_like(keyword, "!")}%"
      active.where("LOWER(posts.title) LIKE :pattern ESCAPE '!' OR LOWER(posts.body) LIKE :pattern ESCAPE '!'", pattern: pattern)
    end
  }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :upcoming, -> { where.not(event_date: nil).where("event_date >= ?", Date.current).order(:event_date) }
  scope :for_user, ->(user) {
    return none unless user.present?
    left_outer_joins(:rsvps)
      .where("posts.user_id = :uid OR rsvps.user_id = :uid", uid: user.id)
      .distinct
  }
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

  def event?
    event_date.present?
  end

  def rsvped_by?(user)
    return false unless user.present?
    rsvps.exists?(user_id: user.id)
  end

  def event_start_time
    return @event_start_time if defined?(@event_start_time)
    to_time_input_value(event_time_parts.first)
  end

  def event_end_time
    return @event_end_time if defined?(@event_end_time)
    parts = event_time_parts
    parts.size > 1 ? to_time_input_value(parts.last) : nil
  end

  def start_time
    return nil unless event_date.present?
    if event_time.present?
      begin
        start_str = event_time.include?("-") ? event_time.split("-").first.strip : event_time
        Time.zone.parse("#{event_date} #{start_str}") || event_date.in_time_zone
      rescue StandardError
        event_date.in_time_zone
      end
    else
      event_date.in_time_zone
    end
  end

  def end_time
    return nil unless event_date.present?
    if event_time.present?
      begin
        end_str = event_time.include?("-") ? event_time.split("-").last.strip : event_time
        parsed = Time.zone.parse("#{event_date} #{end_str}")
        if parsed && start_time && parsed < start_time
          parsed = parsed + 1.day
        end
        parsed || event_date.in_time_zone.end_of_day
      rescue StandardError
        event_date.in_time_zone.end_of_day
      end
    else
      event_date.in_time_zone.end_of_day
    end
  end

  private

  def event_time_parts
    event_time.to_s.split("-").map(&:strip).reject(&:blank?)
  end

  def to_time_input_value(str)
    return nil if str.blank?
    Time.zone.parse("2000-01-01 #{str}")&.strftime("%H:%M")
  rescue StandardError
    nil
  end

  def format_time_for_display(str)
    Time.zone.parse("2000-01-01 #{str}")&.strftime("%-l:%M %p")
  rescue StandardError
    nil
  end

  def compose_event_time
    return unless defined?(@event_start_time) || defined?(@event_end_time)

    start_str = format_time_for_display(@event_start_time) if @event_start_time.present?
    end_str = format_time_for_display(@event_end_time) if @event_end_time.present?

    self.event_time =
      if start_str && end_str && start_str != end_str
        "#{start_str} - #{end_str}"
      else
        start_str
      end
  end

  def event_end_time_requires_start_time
    if @event_end_time.present? && @event_start_time.blank?
      errors.add(:event_start_time, "is required when an end time is set")
    end
  end

  def notify_followers
    Notification.for_new_post(self)
  end

  def expires_at_must_be_in_the_future
    errors.add(:expires_at, "must be in the future") if expires_at <= Time.current
  end

  def event_date_cannot_be_after_expires_at
    if event_time.present? && start_time.present?
      if start_time > expires_at
        errors.add(:event_date, "can't be after the post expires")
      end
    elsif event_date > expires_at.to_date
      errors.add(:event_date, "can't be after the post expires")
    end
  end

  def apply_expiration_preset
    case expiration_preset
    when "Tonight"
      self.expires_at = Time.current.end_of_day if preset_newly_chosen?
    when "This week"
      self.expires_at = Time.current.end_of_week if preset_newly_chosen?
    when "Custom"
      if custom_expires_at.present?
        parsed = custom_expires_at.respond_to?(:in_time_zone) ? custom_expires_at.in_time_zone : Time.zone.parse(custom_expires_at.to_s)
        self.expires_at = parsed if parsed && parsed.change(sec: 0) != expires_at&.change(sec: 0)
      end
    end

    if event_date.present? && (expires_at.blank? || event_rescheduled_without_explicit_expiration?)
      self.expires_at = end_time || event_date.in_time_zone.end_of_day
    end
  end

  def event_rescheduled_without_explicit_expiration?
    persisted? &&
      (will_save_change_to_event_date? || will_save_change_to_event_time?) &&
      !will_save_change_to_expiration_preset? &&
      custom_expires_at.blank?
  end

  def preset_newly_chosen?
    new_record? || will_save_change_to_expiration_preset?
  end
end
