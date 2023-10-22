FactoryBot.define do
  factory :stock_status do
    status { %w[R G Y].sample }
    checked_at { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
    association :product
    association :store
  end
end
