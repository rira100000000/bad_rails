FactoryBot.define do
  factory :user do
    sequence(:name)  { |n| "User#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
    address  { "Tokyo" }
    phone    { "090-0000-0000" }
    point    { 0 }
  end
end
