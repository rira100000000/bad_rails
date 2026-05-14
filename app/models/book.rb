# [BAD-016]
class Book < ApplicationRecord
  belongs_to :seller, class_name: "User"
  belongs_to :category, optional: true
  has_one  :order, dependent: :nullify
  has_many :favorites, dependent: :destroy

  # [BAD-017]
  STATUSES = %w[listed sold shipped received cancelled].freeze

  validates :title,  presence: true
  validates :price,  numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  # [BAD-018]
  scope :listed, -> { where(status: "listed") }
  scope :recent, -> { order(created_at: :desc) }

  # [BAD-019]
  after_save :notify_price_changed, if: :saved_change_to_price?

  # [BAD-020]
  def price_with_tax
    (price * 1.1).to_i
  end

  # [BAD-021]
  def shipping_fee
    if price >= 5000
      0
    elsif price >= 1000
      300
    else
      500
    end
  end

  def total_price
    price_with_tax + shipping_fee
  end

  # [BAD-022]
  def display_price
    "¥#{price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  # [BAD-023]
  def status_label
    case status
    when "listed"    then "出品中"
    when "sold"      then "売却済"
    when "shipped"   then "発送済"
    when "received"  then "受取完了"
    when "cancelled" then "キャンセル"
    else status
    end
  end

  # [BAD-024]
  def mark_as_sold!
    self.status = "sold"
    self.save!
  end

  def mark_as_shipped!
    self.status = "shipped"
    self.save!
  end

  def mark_as_received!
    self.status = "received"
    self.save!
  end

  # [BAD-025]
  def self.search(keyword)
    return all if keyword.blank?
    where("title LIKE '%#{keyword}%' OR author LIKE '%#{keyword}%'")
  end

  private

  def notify_price_changed
    return if seller.blank?
    seller.notify!("出品「#{title}」の価格が更新されました", type: "price_change", target_id: id)
  end
end
