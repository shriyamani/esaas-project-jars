class AddEventFieldsToPostsAndCreateRsvps < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :event_date, :date
    add_column :posts, :event_time, :string
    add_column :posts, :location, :string
    add_index :posts, :event_date

    create_table :rsvps do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true

      t.timestamps
    end

    add_index :rsvps, [ :user_id, :post_id ], unique: true
  end
end

