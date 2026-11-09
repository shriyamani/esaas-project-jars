FactoryBot.define do
  factory :reply do
    post { nil }
    user { nil }
    body { "MyText" }
    anonymous { false }
  end
end
