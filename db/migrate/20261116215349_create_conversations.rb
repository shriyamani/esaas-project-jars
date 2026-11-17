class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :post, null: true, foreign_key: true
      t.string :kind, null: false, default: "direct"
      t.timestamps
    end
    add_index :conversations, :post_id, unique: true,
              where: "kind = 'group'", name: "index_conversations_one_group_per_post"
  end
end