FactoryBot.define do
  factory :store do
    displayname { Faker::Company.name }
    isMidnightPharmacy { Faker::Boolean.boolean }
    isPharmacy { Faker::Boolean.boolean }
    isPrescriptionStoreCollectionAvailable { Faker::Boolean.boolean }
    name { Faker::Company.name }
    ndsasqm { Faker::Number.number(digits: 3) }
    nhsMarket { Faker::Commerce.department }
    openDate { Faker::Date.between(from: '2020-01-01', to: '2022-12-31') }
    store_id { Faker::Number.between(from: 1, to: 9999) }
    primaryCareOrganisation { ['Organisation A', 'Organisation B', 'Organisation C'].sample }
    association :area
    association :manager
  end
end
