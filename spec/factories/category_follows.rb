FactoryBot.define do
  factory :category_follow do
    association :user
    category { "Housing" }
  end
end