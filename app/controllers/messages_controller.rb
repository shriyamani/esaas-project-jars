class MessagesController < ApplicationController
  def create
    conversation = Conversation.for_user(current_user).find(params[:conversation_id])
    message = conversation.messages.build(body: params.dig(:message, :body), user: current_user)

    if message.save
      redirect_to conversation_path(conversation, anchor: "message_composer")
    else
      redirect_to conversation_path(conversation), alert: message.errors.full_messages.to_sentence
    end
  end
end