FactoryBot.define do
  factory :stock_status do
    status { ["R", "G", "Y"].sample }
    checked_at { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
    association :product
    association :store
  end
end