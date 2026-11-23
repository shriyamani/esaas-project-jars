class AddKindToMessages < ActiveRecord::Migration[8.1]
  def change
    # "text" for normal messages; "joined"/"left" for group chat event lines.
    add_column :messages, :kind, :string, default: "text", null: false
  end
end
