class ActivitiesController < ApplicationController
  def show
    post_scope = Post.active.preload(:user, :replies, :likes)

    @my_posts = post_scope.where(user: current_user).newest_first

    replied_post_ids = current_user.replies.select(:post_id)
    group_post_ids = Conversation.for_user(current_user).where(kind: "group").where.not(post_id: nil).select(:post_id)
    @joined_posts = post_scope.where(id: replied_post_ids)
                              .or(post_scope.where(id: group_post_ids))
                              .where.not(user: current_user)
                              .newest_first

    @rsvped_posts = post_scope.where(id: current_user.rsvps.select(:post_id)).newest_first
  end
end
