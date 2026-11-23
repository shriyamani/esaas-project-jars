class AddNameToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :name, :string
  end
end
