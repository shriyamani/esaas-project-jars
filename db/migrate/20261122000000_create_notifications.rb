class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :source, polymorphic: true, null: false
      t.string :kind, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [ :recipient_id, :kind, :source_type, :source_id ],
              unique: true, name: "index_notifications_on_recipient_kind_and_source"
    add_index :notifications, [ :recipient_id, :read_at, :created_at ]
  end
end
