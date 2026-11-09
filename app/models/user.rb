class User < ApplicationRecord
  ALLOWED_DOMAINS = %w[columbia.edu barnard.edu].freeze

  devise :omniauthable, omniauth_providers: [:google_oauth2]

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
