class PostMembership < ApplicationRecord
  belongs_to :post
  belongs_to :user

  after_create :notify_post_author

  validates :user_id, uniqueness: { scope: :post_id }
  validate :cannot_join_own_post

  private

  def cannot_join_own_post
    return unless post && user

    if post.user_id == user.id
      errors.add(:user, "cannot join their own post")
    end
  end

  def notify_post_author
    Notification.for_join(self)
  end
end
