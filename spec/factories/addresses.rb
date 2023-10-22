FactoryBot.define do
  factory :address do
    administrativeArea { Faker::Address.state }
    countryCode { Faker::Address.country_code }
    county { Faker::Address.secondary_address }
    locality { Faker::Address.city }
    postcode { Faker::Address.zip_code }
    street { Faker::Address.street_name }
    town { Faker::Address.city }
    association :store
  end
end