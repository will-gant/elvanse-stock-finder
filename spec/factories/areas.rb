FactoryBot.define do
  factory :area do
    area_id { Faker::Number.number(digits: 3) }
    name { Faker::Address.city }
    association :region
  end
end
