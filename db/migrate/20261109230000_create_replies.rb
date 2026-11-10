class CreateReplies < ActiveRecord::Migration[8.1]
  def up
    if table_exists?(:replies)
      # Earlier branches created this table under a different timestamp.
      rename_column :replies, :posts_id, :post_id if column_exists?(:replies, :posts_id)
      rename_column :replies, :users_id, :user_id if column_exists?(:replies, :users_id)

      change_column_null :replies, :post_id, false
      change_column_null :replies, :user_id, false
      change_column_null :replies, :body, false
      change_column_default :replies, :anonymous, false
      change_column_null :replies, :anonymous, false, false
      add_index :replies, :post_id unless index_exists?(:replies, :post_id)
      add_index :replies, :user_id unless index_exists?(:replies, :user_id)
      add_foreign_key :replies, :posts unless foreign_key_exists?(:replies, :posts, column: :post_id)
      add_foreign_key :replies, :users unless foreign_key_exists?(:replies, :users, column: :user_id)
      return
    end

    create_table :replies do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.boolean :anonymous, null: false, default: false
      t.timestamps
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Replies may predate this migration; preserve the existing table."
  end
end
