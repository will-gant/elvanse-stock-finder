FactoryBot.define do
  factory :region do
    name { Faker::Address.state }
    region_id { Faker::Number.between(from: 1, to: 99) }
  end
end
