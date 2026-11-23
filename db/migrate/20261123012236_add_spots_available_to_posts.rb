class AddSpotsAvailableToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :spots_available, :integer
  end
end
