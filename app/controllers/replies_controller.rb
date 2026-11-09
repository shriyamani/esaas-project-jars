class RepliesController < ApplicationController
  # TODO: ADAPT if Person 1 uses a different
  # authentication method.
  before_action :authenticate_user!

  def create
    # TODO: ADAPT Post and :post_id if the
    # parent model or nested route differs.
    @post = Post.find(params[:post_id])

    @reply = @post.replies.build(reply_params)

    # TODO: ADAPT if the authentication helper
    # is not current_user.
    @reply.user = current_user

    if @reply.save
      redirect_to @post,
                  notice: "Reply posted successfully."
    else
      redirect_to @post,
                  alert: @reply.errors.full_messages.to_sentence
    end
  end

  private

  def reply_params
    params.require(:reply).permit(:body, :anonymous)
  end
end