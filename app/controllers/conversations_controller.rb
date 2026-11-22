class ConversationsController < ApplicationController
  def index
    @tab = params[:tab] == "contacts" ? "contacts" : "chats"

    if @tab == "contacts"
      @contacts = current_user.contacts
    else
      @conversations = Conversation.for_user(current_user)
                                   .where("conversations.kind = 'group' OR EXISTS (SELECT 1 FROM messages WHERE messages.conversation_id = conversations.id)")
                                   .includes(:participants, :post)
                                   .order(updated_at: :desc)
    end
  end

  def show
    @conversation = Conversation.for_user(current_user).find(params[:id])
    @messages = @conversation.messages.includes(:user).order(:created_at, :id).to_a
    @message = Message.new
    unless request.headers["X-Sec-Purpose"] == "prefetch"
      @conversation.mark_read_by(current_user)
      current_user.notifications.unread.where(source_type: "Message", source_id: @conversation.messages.select(:id))
                  .update_all(read_at: Time.current)
    end
  end

  def new
    @email = params[:email]
  end

  def create
    if params[:user_id].blank? && params[:email].to_s.strip.empty?
      return redirect_to new_conversation_path, alert: "Enter an email address."
    end

    other = params[:user_id].present? ? User.find(params[:user_id]) : User.find_by(email: params[:email].to_s.strip.downcase)

    if other.nil?
      redirect_to new_conversation_path(email: params[:email]), alert: "No LionDen account uses that email."
    elsif other == current_user
      redirect_back fallback_location: conversations_path, alert: "You can't message yourself."
    else
      redirect_to conversation_path(Conversation.direct_between(current_user, other))
    end
  end
end
