FactoryBot.define do
  factory :area do
    area_id { Faker::Number.between(from: 10, to: 999) }
    name { Faker::Address.city }
    association :region
  end
end