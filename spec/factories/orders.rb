FactoryBot.define do
  factory :order do
    association :book
    association :buyer, factory: :user
    status       { "paid" }
    total_price  { 1100 }
    shipping_fee { 300 }
    tax          { 100 }
    payment_method { "credit_card" }
    paid_at      { Time.current }
  end
end
