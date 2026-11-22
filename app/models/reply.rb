class Reply < ApplicationRecord
  belongs_to :post
  belongs_to :user
  has_many :notifications, as: :source, dependent: :destroy

  after_create :notify_post_author

  validates :body,
            presence: true,
            length: { maximum: 2000 }

  validate :post_must_be_active, on: :create

  def display_author
    anonymous? ? "Anonymous" : user&.name
  end

  private

  def notify_post_author
    Notification.for_reply(self)
  end

  def post_must_be_active
    return if post.nil?

    if post.expires_at.blank? ||
       post.expires_at <= Time.current
      errors.add(:post, "has expired")
    end
  end
end
