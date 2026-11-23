class Notification < ApplicationRecord
  KINDS = %w[new_post reply join leave message].freeze

  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :source, polymorphic: true

  validates :kind, inclusion: { in: KINDS }

  scope :unread, -> { where(read_at: nil) }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  # Public hooks for post, reply, RSVP, and messaging flows.
  def self.for_new_post(post)
    NotificationCreationService.for_new_post(post)
  end

  def self.for_reply(reply)
    NotificationCreationService.for_reply(reply)
  end

  def self.for_join(rsvp)
    NotificationCreationService.for_join(rsvp)
  end

  def self.for_post_join(membership)
    NotificationCreationService.for_post_join(membership)
  end

  def self.for_post_leave(membership)
    NotificationCreationService.for_post_leave(membership)
  end

  def self.for_message(message)
    NotificationCreationService.for_message(message)
  end

  def summary
    return nil if source.nil?

    case kind
    when "new_post" then "New post in #{source.category}: #{source.title}"
    when "reply" then "#{source.anonymous? ? 'Someone' : actor.name} replied to your post: #{source.post.title}"
    when "join" then "#{actor.name} joined your post: #{related_post.title}"
    when "leave" then "#{actor.name} left your post: #{related_post.title}"
    when "message" then "New message in #{source.conversation.title_for(recipient)}"
    end
  end

  def destination
    return nil if source.nil?

    case kind
    when "new_post" then source
    when "reply", "join", "leave" then related_post
    when "message" then source.conversation
    end
  end

  private

  def related_post
    source.is_a?(Post) ? source : source.post
  end
end
