FactoryBot.define do
  factory :random_id, class: Integer do
    skip_create
    initialize_with { rand(1..9_999) }
  end
end