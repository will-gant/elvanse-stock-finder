FactoryBot.define do
  factory :status do
    code { Faker::Number.number(digits: 3) }
    text { "Open" }
    association :store
  end
end