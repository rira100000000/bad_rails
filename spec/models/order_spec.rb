require "rails_helper"

RSpec.describe Order, type: :model do
  describe "#reviewable?" do
    it "is reviewable when received and no review yet" do
      order = create(:order, status: "received")
      expect(order.reviewable?).to be true
    end

    it "is not reviewable when not received" do
      order = create(:order, status: "paid")
      expect(order.reviewable?).to be false
    end
  end

  describe "#cancel!" do
    it "marks order cancelled and book listed" do
      order = create(:order, status: "paid")
      order.book.update!(status: "sold")
      order.cancel!
      expect(order.reload.status).to eq("cancelled")
      expect(order.book.reload.status).to eq("listed")
    end
  end
end
