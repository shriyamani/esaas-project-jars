class Rsvp < ApplicationRecord
  belongs_to :user
  belongs_to :post
  has_many :notifications, as: :source, dependent: :destroy

  after_create :notify_post_author

  validates :user_id, uniqueness: { scope: :post_id, message: "has already RSVP'd to this event" }

  private

  def notify_post_author
    Notification.for_join(self)
  end
end
