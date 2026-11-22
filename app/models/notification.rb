class Notification < ApplicationRecord
  KINDS = %w[new_post reply join message].freeze

  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User"
  belongs_to :source, polymorphic: true

  validates :kind, inclusion: { in: KINDS }

  scope :unread, -> { where(read_at: nil) }
  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  # Public hooks for post, reply, RSVP, and messaging flows.
  def self.for_new_post(post)
    User.joins(:category_follows)
        .where(category_follows: { category: post.category })
        .where.not(id: post.user_id)
        .distinct.find_each do |recipient|
      deliver(recipient: recipient, actor: post.user, kind: "new_post", source: post)
    end
  end

  def self.for_reply(reply)
    return if reply.user_id == reply.post.user_id

    deliver(recipient: reply.post.user, actor: reply.user, kind: "reply", source: reply)
  end

  def self.for_join(rsvp)
    return if rsvp.user_id == rsvp.post.user_id

    deliver(recipient: rsvp.post.user, actor: rsvp.user, kind: "join", source: rsvp)
  end

  def self.for_message(message)
    message.conversation.participants.where.not(id: message.user_id).find_each do |recipient|
      deliver(recipient: recipient, actor: message.user, kind: "message", source: message)
    end
  end

  def self.deliver(recipient:, actor:, kind:, source:)
    create_or_find_by!(recipient: recipient, actor: actor, kind: kind, source: source)
  end

  def summary
    case kind
    when "new_post" then "New post in #{source.category}: #{source.title}"
    when "reply" then "#{source.anonymous? ? 'Someone' : actor.name} replied to your post: #{source.post.title}"
    when "join" then "#{actor.name} joined your post: #{source.post.title}"
    when "message" then "New message in #{source.conversation.title_for(recipient)}"
    end
  end

  def destination
    case kind
    when "new_post" then source
    when "reply", "join" then source.post
    when "message" then source.conversation
    end
  end
end
