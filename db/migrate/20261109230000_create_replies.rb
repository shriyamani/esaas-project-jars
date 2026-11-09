class CreateReplies < ActiveRecord::Migration[8.1]
  def change
    create_table :replies do |t|
      t.references :posts, null: false, foreign_key: true
      t.references :users, null: false, foreign_key: true
      t.text :body, null: false
      t.boolean :anonymous, null: false, default: false
      t.timestamps
    end
  end
end
