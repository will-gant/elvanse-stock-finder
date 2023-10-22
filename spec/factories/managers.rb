FactoryBot.define do
  factory :manager do
    email { Faker::Internet.email }
    name { Faker::Name.name }
  end
end
