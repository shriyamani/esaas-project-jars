class RepliesController < ApplicationController
  before_action :set_owned_reply, only: [ :edit, :update, :destroy ]

  def create
    @post = Post.find(params[:post_id])
    @reply = @post.replies.build(reply_params)
    @reply.user = current_user

    if @reply.save
      redirect_to @post, notice: "Reply posted successfully."
    elsif @post.expires_at.blank? || @post.expires_at <= Time.current
      redirect_to posts_path, alert: "This post has expired."
    else
      redirect_to @post, alert: @reply.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @reply.update(reply_params)
      redirect_to reply_return_path, notice: "Reply updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reply.destroy!
    redirect_to reply_return_path, notice: "Reply deleted successfully.", status: :see_other
  end

  private

  def set_owned_reply
    @post = Post.find(params[:post_id])
    @reply = @post.replies.where(user: current_user).find(params[:id])
  end

  def reply_return_path
    @post.expires_at.present? && @post.expires_at > Time.current ? post_path(@post) : posts_path
  end


  def reply_params
    params.require(:reply).permit(:body, :anonymous)
  end
end
