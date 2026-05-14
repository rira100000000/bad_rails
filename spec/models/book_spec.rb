require "rails_helper"

RSpec.describe Book, type: :model do
  describe "price calculations" do
    it "applies 10% tax to price_with_tax" do
      book = build(:book, price: 1000)
      expect(book.price_with_tax).to eq(1100)
    end

    it "returns 0 shipping for high-priced books" do
      expect(build(:book, price: 5000).shipping_fee).to eq(0)
    end

    it "returns 300 shipping for mid-priced books" do
      expect(build(:book, price: 1500).shipping_fee).to eq(300)
    end

    it "returns 500 shipping for low-priced books" do
      expect(build(:book, price: 800).shipping_fee).to eq(500)
    end
  end

  describe "state transitions" do
    let(:book) { create(:book) }

    it "marks as sold" do
      book.mark_as_sold!
      expect(book.reload.status).to eq("sold")
    end

    it "marks as shipped" do
      book.mark_as_shipped!
      expect(book.reload.status).to eq("shipped")
    end
  end

  describe ".search" do
    before do
      create(:book, title: "Ruby実践入門", author: "佐藤")
      create(:book, title: "Rails本",     author: "鈴木")
    end

    it "matches by title" do
      expect(Book.search("Ruby").count).to eq(1)
    end

    it "matches by author" do
      expect(Book.search("鈴木").count).to eq(1)
    end

    it "returns all when keyword blank" do
      expect(Book.search("").count).to eq(2)
    end

    # [BAD-088]
  end
end
