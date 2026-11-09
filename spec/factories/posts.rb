FactoryBot.define do
  factory :post do
    association :user
    title { "Looking for roommate" }
    body { "Spacious 2 bedroom near campus." }
    category { "Housing" }
    anonymous { false }
    expires_at { 3.days.from_now }
  end
end
