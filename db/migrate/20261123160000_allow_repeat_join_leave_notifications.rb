class AllowRepeatJoinLeaveNotifications < ActiveRecord::Migration[8.1]
  OLD_INDEX = "index_notifications_on_recipient_kind_and_source".freeze
  COLUMNS = [ :recipient_id, :kind, :source_type, :source_id ].freeze
  # Join/leave events on a post are an audit trail: many people (or the same
  # person repeatedly) can join and leave one post, so they are exempt from
  # de-duplication. Every other notification stays unique per source.
  EVENT_ROWS = "kind IN ('join', 'leave') AND source_type = 'Post'".freeze

  def up
    remove_index :notifications, name: OLD_INDEX

    # Join notifications used to point at the PostMembership, which is deleted
    # when someone leaves. Re-point them at the post so they survive.
    execute <<~SQL
      UPDATE notifications
      SET source_type = 'Post',
          source_id = (SELECT post_id FROM post_memberships WHERE post_memberships.id = notifications.source_id)
      WHERE source_type = 'PostMembership'
        AND EXISTS (SELECT 1 FROM post_memberships WHERE post_memberships.id = notifications.source_id)
    SQL
    execute "DELETE FROM notifications WHERE source_type = 'PostMembership'"

    add_index :notifications, COLUMNS, unique: true, name: OLD_INDEX, where: "NOT (#{EVENT_ROWS})"
  end

  def down
    remove_index :notifications, name: OLD_INDEX
    execute "DELETE FROM notifications WHERE #{EVENT_ROWS}"
    add_index :notifications, COLUMNS, unique: true, name: OLD_INDEX
  end
end
