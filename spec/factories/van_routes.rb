FactoryBot.define do
  factory :van_route do
    code { Faker::Alphanumeric.alpha(number: 4) }
    association :store
  end
end