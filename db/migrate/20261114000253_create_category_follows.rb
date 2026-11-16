class CreateCategoryFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :category_follows do |t|
      t.references :user, null: false, foreign_key: true
      t.string :category, null: false
      t.timestamps
    end
    add_index :category_follows, [:user_id, :category], unique: true
  end
end
