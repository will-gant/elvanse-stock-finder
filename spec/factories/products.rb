FactoryBot.define do
  factory :product do
    dose { "#{[10, 20, 30, 40, 50, 60, 70].sample}mg" }
    product_id { Faker::Number.number(digits: 17) }
    association :medicine
  end
end
