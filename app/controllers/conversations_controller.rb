class ConversationsController < ApplicationController
  def index
    @conversations = Conversation.for_user(current_user)
                                 .includes(:participants, :post)
                                 .order(updated_at: :desc)
  end

  def show
    @conversation = Conversation.for_user(current_user).find(params[:id])
    @messages = @conversation.messages.includes(:user).order(:created_at, :id)
    @message = Message.new
    @conversation.mark_read_by(current_user) unless request.headers["X-Sec-Purpose"] == "prefetch"
  end
end