class MessagesController < ApplicationController
  before_action :set_conversation
  before_action :set_own_message, only: [ :update ]

  def create
    message = @conversation.messages.build(body: params.dig(:message, :body), user: current_user)

    if message.save
      redirect_to conversation_path(@conversation, anchor: "message_composer")
    else
      redirect_to conversation_path(@conversation), alert: message.errors.full_messages.to_sentence
    end
  end

  def update
    unless @message.editable_by?(current_user)
      return redirect_to conversation_path(@conversation),
                         alert: "Messages can only be edited within 15 minutes of sending."
    end

    if @message.update(body: params.dig(:message, :body))
      redirect_to conversation_path(@conversation, anchor: helpers.dom_id(@message))
    else
      redirect_to conversation_path(@conversation, editing: @message.id),
                  alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def set_conversation
    @conversation = Conversation.for_user(current_user).find(params[:conversation_id])
  end

  def set_own_message
    @message = @conversation.messages.texts.where(user: current_user).find(params[:id])
  end
end