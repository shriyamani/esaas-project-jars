class Rsvp < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :user_id, uniqueness: { scope: :post_id, message: "has already RSVP'd to this event" }
end

