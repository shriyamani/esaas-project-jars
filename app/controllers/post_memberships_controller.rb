
class PostMembershipsController < ApplicationController
  before_action :set_post

  def create
    if @post.spots_available.nil?
        return redirect_to @post, alert: "This post does not have spots available."
    end

    if @post.user == current_user
      return redirect_to @post, alert: "You cannot join your own post."
    end

    if @post.expires_at <= Time.current
      return redirect_to posts_path, alert: "This post has expired."
    end

    if @post.joined_by?(current_user)
      return redirect_to @post, alert: "You have already joined this post."
    end

    conversation = nil

    begin
      Post.transaction do
        Post.where(id: @post.id).update_all("updated_at = updated_at")
        @post.reload

        if @post.spots_available.nil?
            raise ActiveRecord::RecordNotSaved, "This post does not have spots available."
        end

        if @post.expires_at <= Time.current
          raise ActiveRecord::RecordInvalid.new(@post)
        end

        if @post.full?
          raise ActiveRecord::RecordNotSaved, "This post is full."
        end

        membership = @post.post_memberships.create!(user: current_user)

        conversation = @post.conversations.find_or_create_by!(kind: "group")

        conversation.conversation_participants.find_or_create_by!(
          user: @post.user
        )

        conversation.conversation_participants.find_or_create_by!(
          user: current_user
        )
      end

      redirect_to conversation_path(conversation), notice: "You joined this post."
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
        redirect_to @post, alert: "Unable to join this post. It may be full or expired."
    rescue ActiveRecord::StatementInvalid => e
        raise unless e.cause.is_a?(SQLite3::BusyException)

        redirect_to @post, alert: "This post is busy. Please try again."
    end
  end

  def destroy
    Post.transaction do
      Post.where(id: @post.id).update_all("updated_at = updated_at")

      membership = @post.post_memberships.find_by(user: current_user)

      if membership
        membership.destroy!

        conversation = @post.conversations.find_by(kind: "group")

        if conversation
          conversation.conversation_participants
                      .where(user: current_user)
                      .destroy_all
        end
      end
    end

    redirect_to @post, notice: "You left this post."
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
