FactoryBot.define do
  factory :grid_location do
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    propertyEasting { Faker::Number.number(digits: 6) }
    propertyNorthing { Faker::Number.number(digits: 6) }
    association :address
  end
end