FactoryBot.define do
  factory :rsvp do
    association :user
    association :post
  end
end

