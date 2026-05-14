FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category#{n}" }
  end

  factory :book do
    sequence(:title) { |n| "Book#{n}" }
    author    { "山田太郎" }
    description { "test" }
    price     { 1000 }
    status    { "listed" }
    condition { "普通" }
    association :seller, factory: :user
    category
  end
end
