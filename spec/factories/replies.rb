FactoryBot.define do
  factory :reply do
    association :post
    association :user
    body { "MyText" }
    anonymous { false }
  end
end
