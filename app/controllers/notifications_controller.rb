class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications.recent_first.includes(:actor, :source)
  end

  def open
    notification = current_user.notifications.find(params[:id])
    notification.update!(read_at: Time.current) unless notification.read_at?

    destination = notification.destination
    path = case destination
    when Post
      destination.expires_at > Time.current ? post_path(destination) : posts_path
    when Conversation
      destination.participant?(current_user) ? conversation_path(destination) : conversations_path
    else
      notifications_path
    end

    redirect_to path, status: :see_other
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_back fallback_location: notifications_path, status: :see_other
  end
end
