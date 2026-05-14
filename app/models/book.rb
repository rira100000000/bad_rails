# [BAD] Book も Fat Model 化していて、商品 / 在庫 / 出品 / 価格計算 / 表示整形 を一手に。
class Book < ApplicationRecord
  belongs_to :seller, class_name: "User"
  belongs_to :category, optional: true
  has_one  :order, dependent: :nullify
  has_many :favorites, dependent: :destroy

  # [BAD] status は ただの String。 enum も AASM も使わず文字列比較で全レイヤーに散らかる。
  STATUSES = %w[listed sold shipped received cancelled].freeze

  validates :title,  presence: true
  validates :price,  numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }

  # [BAD] scope と class メソッド、 where がそこら中に書かれていて検索条件の根拠が複数。
  scope :listed, -> { where(status: "listed") }
  scope :recent, -> { order(created_at: :desc) }

  # [BAD] after_save で勝手にメール送信。 値段更新するたびに seller にメールが飛ぶ。
  after_save :notify_price_changed, if: :saved_change_to_price?

  # [BAD] 税計算が Book にも、 User にも、 OrdersController にも、 View にも書かれている。 DRY 違反。
  def price_with_tax
    (price * 1.1).to_i
  end

  # [BAD] 送料計算その1。Book にある。 OrdersController と View にも別実装。
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

  # [BAD] 表示整形が Model に。 数値→文字列変換は Helper で。
  def display_price
    "¥#{price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

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

  # [BAD] 状態遷移メソッドはあるが、 OrdersController でも status を直書きしている箇所がある(整合性なし)。
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

  # [BAD] 検索を Book.search のクラスメソッドで提供しているが、 BooksController#index でも別実装で SQL を組んでいる。
  def self.search(keyword)
    return all if keyword.blank?
    # [BAD] SQL Injection の余地あり! 文字列補間で LIKE を組んでいる。
    where("title LIKE '%#{keyword}%' OR author LIKE '%#{keyword}%'")
  end

  private

  def notify_price_changed
    return if seller.blank?
    seller.notify!("出品「#{title}」の価格が更新されました", type: "price_change", target_id: id)
  end
end
