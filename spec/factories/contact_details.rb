FactoryBot.define do
  factory :contact_detail do
    phone { Faker::PhoneNumber.phone_number }
    association :store
  end
end