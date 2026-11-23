FactoryBot.define do
  factory :post_membership do
    association :post
    association :user
  end
end
