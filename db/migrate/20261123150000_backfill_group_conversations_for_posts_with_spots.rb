class BackfillGroupConversationsForPostsWithSpots < ActiveRecord::Migration[8.1]
  class MigrationPost < ActiveRecord::Base
    self.table_name = "posts"
  end

  class MigrationConversation < ActiveRecord::Base
    self.table_name = "conversations"
  end

  class MigrationParticipant < ActiveRecord::Base
    self.table_name = "conversation_participants"
  end

  def up
    MigrationPost.where.not(spots_available: nil).find_each do |post|
      conversation = MigrationConversation.find_or_create_by!(post_id: post.id, kind: "group")
      MigrationParticipant.find_or_create_by!(conversation_id: conversation.id, user_id: post.user_id)
    end
  end

  def down
    # Data-only backfill; nothing to undo.
  end
end
