class PostMembership < ApplicationRecord
  belongs_to :post
  belongs_to :user

  after_create :notify_post_author_of_join
  after_destroy :notify_post_author_of_leave, unless: :destroyed_by_association

  validates :user_id, uniqueness: { scope: :post_id }
  validate :cannot_join_own_post

  private

  def cannot_join_own_post
    return unless post && user

    if post.user_id == user.id
      errors.add(:user, "cannot join their own post")
    end
  end

  def notify_post_author_of_join
    Notification.for_post_join(self)
  end

  def notify_post_author_of_leave
    Notification.for_post_leave(self)
  end
end
