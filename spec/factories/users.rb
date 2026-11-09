FactoryBot.define do
  factory :user do
    name { "Testing Tester" }
    sequence(:email) { |n| "student#{n}@barnard.edu" }
  end
end
