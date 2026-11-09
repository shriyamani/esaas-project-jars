class Reply < ApplicationRecord
  belongs_to :post
  belongs_to :user
  
  validates :body,
            presence: true,
            length: { maximum: 2000 }

  validate :post_must_be_active, on: :create

  def display_author
    anonymous? ? "Anonymous" : user&.name
  end

  private

  def post_must_be_active
    return if post.nil?

    if post.expires_at.blank? ||
       post.expires_at <= Time.current
      errors.add(:post, "has expired")
    end
  end
end
