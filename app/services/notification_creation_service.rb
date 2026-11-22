class NotificationCreationService
  class << self
    def for_new_post(post)
      User.joins(:category_follows)
          .where(category_follows: { category: post.category })
          .where.not(id: post.user_id)
          .distinct.find_each do |recipient|
        deliver(recipient: recipient, actor: post.user, kind: "new_post", source: post)
      end
    end

    def for_reply(reply)
      return if reply.user_id == reply.post.user_id

      deliver(recipient: reply.post.user, actor: reply.user, kind: "reply", source: reply)
    end

    def for_join(rsvp)
      return if rsvp.user_id == rsvp.post.user_id

      deliver(recipient: rsvp.post.user, actor: rsvp.user, kind: "join", source: rsvp)
    end

    def for_message(message)
      message.conversation.participants.where.not(id: message.user_id).find_each do |recipient|
        deliver(recipient: recipient, actor: message.user, kind: "message", source: message)
      end
    end

    private

    def deliver(recipient:, actor:, kind:, source:)
      Notification.create_or_find_by!(recipient: recipient, actor: actor, kind: kind, source: source)
    end
  end
end
