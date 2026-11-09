class RepliesController < ApplicationController
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

  private

  def reply_params
    params.require(:reply).permit(:body, :anonymous)
  end
end
