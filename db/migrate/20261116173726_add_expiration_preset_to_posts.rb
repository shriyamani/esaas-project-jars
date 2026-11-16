class AddExpirationPresetToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :expiration_preset, :string
  end
end
