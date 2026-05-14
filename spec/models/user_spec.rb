require "rails_helper"

# [BAD-087]
RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe "validations" do
    it "is valid with name and email" do
      expect(build(:user)).to be_valid
    end

    it "is invalid without name" do
      u = build(:user, name: nil)
      expect(u).not_to be_valid
    end

    it "rejects duplicate email" do
      create(:user, email: "dup@example.com")
      u = build(:user, email: "dup@example.com")
      expect(u).not_to be_valid
    end
  end

  describe "#average_rating" do
    it "returns 0 when no reviews" do
      expect(user.average_rating).to eq(0)
    end
  end

  describe "#can_buy?" do
    let(:seller) { create(:user) }
    let(:book)   { create(:book, seller: seller, status: "listed") }

    it "returns true for a different user buying a listed book" do
      expect(user.can_buy?(book)).to be true
    end

    it "returns false if the user is the seller" do
      expect(seller.can_buy?(book)).to be false
    end

    it "returns false if the book is not listed" do
      book.update!(status: "sold")
      expect(user.can_buy?(book)).to be false
    end
  end

  describe "#total_spent" do
    it "sums up purchase totals" do
      create(:order, buyer: user, total_price: 100)
      create(:order, buyer: user, total_price: 200)
      expect(user.total_spent).to eq(300)
    end
  end
end
