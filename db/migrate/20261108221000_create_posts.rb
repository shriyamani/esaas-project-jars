class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.string :category, null: false
      t.boolean :anonymous, default: false, null: false
      t.datetime :expires_at, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps null: false
    end

    add_index :posts, :expires_at
    add_index :posts, :category
  end
end
