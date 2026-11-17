FactoryBot.define do
  factory :message do
    association :user
    conversation { association :conversation, participants: [ user ] }
    body { "Hello there" }
  end
end
