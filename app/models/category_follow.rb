class CategoryFollow < ApplicationRecord
  belongs_to :user
  validates :category, inclusion: { in: Post::CATEGORIES }
  validates :category, uniqueness: { scope: :user_id }
end