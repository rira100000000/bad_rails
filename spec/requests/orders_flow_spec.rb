require "rails_helper"

# ゴールデンパス: 出品→ログイン→購入→発送→受取
RSpec.describe "Orders flow", type: :request do
  let!(:seller) { create(:user, email: "seller@example.com") }
  let!(:buyer)  { create(:user, email: "buyer@example.com") }
  let!(:book)   { create(:book, seller: seller, price: 1000, status: "listed") }

  def login_as(user)
    post "/login", params: { email: user.email, password: "password" }
  end

  it "buyer can purchase via BooksController#buy" do
    login_as(buyer)
    expect {
      post "/books/#{book.id}/buy"
    }.to change(Order, :count).by(1)
    expect(book.reload.status).to eq("sold")
    expect(Order.last.status).to eq("paid")
  end

  it "buyer can purchase via OrdersController#create" do
    login_as(buyer)
    expect {
      post "/orders", params: { book_id: book.id }
    }.to change(Order, :count).by(1)
    expect(response).to redirect_to(Order.last)
    expect(book.reload.status).to eq("sold")
  end

  # [BAD-089]
  it "two purchase paths produce different totals (bug surface)" do
    login_as(buyer)
    book2 = create(:book, seller: seller, price: 1000)
    post "/books/#{book.id}/buy"
    post "/orders", params: { book_id: book2.id }
    a, b = Order.last(2)
    expect(a.total_price).not_to eq(b.total_price)
  end

  it "seller cannot buy own book" do
    login_as(seller)
    post "/orders", params: { book_id: book.id }
    expect(response).to redirect_to(book_path(book))
    expect(book.reload.status).to eq("listed")
  end
end
