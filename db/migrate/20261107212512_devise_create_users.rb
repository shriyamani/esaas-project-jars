class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,      null: false
      t.string :name,       null: false
      t.timestamps null: false
    end

    add_index :users, :email, unique: true
  end
end
