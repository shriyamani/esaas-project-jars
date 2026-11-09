class Post < ApplicationRecord
  CATEGORIES = [ "Social", "Academics", "Housing", "Buy/Sell", "Travel", "Help" ].freeze
  EXPIRATION_PRESETS = [ "Tonight", "This week", "Custom" ].freeze

  attr_accessor :expiration_preset, :custom_expires_at

  belongs_to :user

  before_validation :apply_expiration_preset

  validates :title, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :expires_at, presence: true
  validate :expires_at_must_be_in_the_future, if: -> { expires_at.present? && expires_at_changed? }

  scope :active, -> { where("expires_at > ?", Time.current) }

  def display_author
    anonymous? ? "Anonymous" : user&.name
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
