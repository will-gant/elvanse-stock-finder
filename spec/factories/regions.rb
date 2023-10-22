FactoryBot.define do
  factory :region do
    name { Faker::Address.state }
    region_id { Faker::Number.number(digits: 2) }
  end
end
