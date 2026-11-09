class Reply < ApplicationRecord
  belongs_to :post
  belongs_to :user
  
  validates :body,
            presence: true,
            length: { maximum: 2000 }

  validate :post_must_be_active, on: :create

  private

  def post_must_be_active
    return if post.nil?

    # TODO: ADAPT to Person 2's expiration logic.
    # This assumes Post has expires_at.
    if post.expires_at.blank? ||
       post.expires_at <= Time.current
      errors.add(:post, "has expired")
    end
  end
end
