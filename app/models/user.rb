# [BAD] God Object / Fat Model の代表例。
# User がアプリのほぼ全部のドメイン知識を抱え込んでいる。
# 出品計算、購入計算、通知、統計、メール、認可、フォーマット…なんでもござれ。
class User < ApplicationRecord
  has_secure_password

  # [BAD] 関連が爆発している。User がドメインの中心だと錯覚してしまう。
  has_many :listings,      class_name: "Book",         foreign_key: :seller_id, dependent: :destroy
  has_many :purchases,     class_name: "Order",        foreign_key: :buyer_id,  dependent: :destroy
  has_many :reviews_given, class_name: "Review",       foreign_key: :reviewer_id
  has_many :reviews_received, class_name: "Review",    foreign_key: :target_user_id
  has_many :favorites,     dependent: :destroy
  has_many :favorite_books, through: :favorites, source: :book
  has_many :notifications, dependent: :destroy

  # [BAD] validates は雑。email形式チェックは正規表現を直書きでメンテ困難。
  validates :name,  presence: true
  validates :email, presence: true, uniqueness: true, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }

  # [BAD] after_create で挨拶メールを送る → テスト/開発でメールが飛ぶ、SMTP 障害で登録失敗。
  after_create :send_welcome_email
  # [BAD] after_save で通知を作る → 更新するたびに通知レコードが増殖。
  after_save :create_signup_notification, if: :saved_change_to_id?

  # ===== 出品関係(本来 Book / Listing サービスに置くべき) =====
  def listed_books_count
    listings.where(status: "listed").count
  end

  def sold_books_count
    listings.where(status: "sold").count
  end

  def total_sales_amount
    # [BAD] 売上の集計ロジックを User が持っている。N+1 と税計算の二重計上のリスク。
    total = 0
    listings.where(status: "sold").each do |b|
      total += b.price + (b.price * 0.1).to_i # [BAD] 税率10%ハードコード
    end
    total
  end

  # ===== 購入関係 =====
  def total_spent
    # [BAD] purchases を1件ずつなめる。 sum でいいのに。
    s = 0
    purchases.each { |o| s += o.total_price.to_i }
    s
  end

  def can_buy?(book)
    # [BAD] 認可ロジックが User に。Book と相互参照していて Tell, Don't Ask 違反。
    return false if book.seller_id == self.id
    return false if book.status != "listed"
    true
  end

  # ===== レビュー関係(本来 Review/Rating サービス) =====
  def average_rating
    # [BAD] view から呼ばれて N+1 になりがち。 集計クエリでやればよい。
    ratings = reviews_received.map(&:rating)
    return 0 if ratings.empty?
    (ratings.sum.to_f / ratings.size).round(2)
  end

  def rating_label
    # [BAD] プレゼンテーション層のロジックがモデルに。View Helper でやるべき。
    r = average_rating
    if r >= 4.5
      "★★★★★ 神出品者"
    elsif r >= 4.0
      "★★★★ 優良"
    elsif r >= 3.0
      "★★★ 普通"
    elsif r > 0
      "★★ 要注意"
    else
      "未評価"
    end
  end

  # ===== 通知 =====
  def unread_notifications_count
    notifications.where(read: false).count
  end

  def notify!(message, type: "info", target_id: nil)
    # [BAD] User が Notification の生成方法を知っている。逆向きの依存。
    notifications.create!(message: message, notification_type: type, target_id: target_id, read: false)
  end

  # ===== ポイント =====
  POINT_GRANT_FOR_PURCHASE = 50  # [BAD] マジックナンバー風の定数だが、結局色んなところで生数字も使う

  def grant_point_for_purchase!(order)
    # [BAD] ポイント付与ロジックが User にある。 ポイントポリシーが変わるたびに User を直す羽目に。
    self.point += (order.total_price * 0.01).to_i + 10
    self.save!
  end

  # ===== 統計 =====
  def stats
    # [BAD] 統計用ハッシュを返すメソッド。 View でも Controller でも使われていて密結合。
    {
      listed:   listed_books_count,
      sold:     sold_books_count,
      sales:    total_sales_amount,
      spent:    total_spent,
      rating:   average_rating,
      label:    rating_label,
      notif:    unread_notifications_count
    }
  end

  # ===== フォーマッタ(プレゼンテーション層) =====
  def display_name
    # [BAD] View 用の整形が Model に。
    admin? ? "[管理者] #{name}" : name
  end

  def masked_phone
    return "" if phone.blank?
    phone.gsub(/\d/, "*")
  end

  # ===== 認証/認可 =====
  def admin?
    !!admin
  end

  def self.authenticate(email, password)
    # [BAD] このクラスメソッドはあるけど、 Controller では User.find_by + authenticate を直接呼ぶ箇所もあり一貫性なし。
    user = find_by(email: email)
    user&.authenticate(password) ? user : nil
  end

  private

  def send_welcome_email
    # [BAD] コールバックでメール送信。テストで止められず、失敗時にユーザ登録ごと巻き戻る。
    UserMailer.welcome(self).deliver_now rescue nil
  end

  def create_signup_notification
    Notification.create!(user_id: self.id, message: "ようこそ BadBooks へ!", notification_type: "welcome", read: false)
  end
end
