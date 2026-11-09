class CreateReplies < ActiveRecord::Migration[8.1]
  def change
    create_table :replies do |t|
      # TODO: ADAPT if Person 2's model is not Post.
      t.references :posts, null: false, foreign_key: true
     
      # TODO: ADAPT if Person 1's account model is not User.
      t.references :users, null: false, foreign_key: true
      t.text :body
      t.boolean :anonymous

      t.timestamps
    end
  end
end
