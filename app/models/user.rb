# [BAD-001]
class User < ApplicationRecord
  has_secure_password

  # [BAD-002]
  has_many :listings,      class_name: "Book",         foreign_key: :seller_id, dependent: :destroy
  has_many :purchases,     class_name: "Order",        foreign_key: :buyer_id,  dependent: :destroy
  has_many :reviews_given, class_name: "Review",       foreign_key: :reviewer_id
  has_many :reviews_received, class_name: "Review",    foreign_key: :target_user_id
  has_many :favorites,     dependent: :destroy
  has_many :favorite_books, through: :favorites, source: :book
  has_many :notifications, dependent: :destroy

  # [BAD-003]
  validates :name,  presence: true
  validates :email, presence: true, uniqueness: true, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i }

  # [BAD-004]
  after_create :send_welcome_email
  # [BAD-005]
  after_save :create_signup_notification, if: :saved_change_to_id?

  def listed_books_count
    listings.where(status: "listed").count
  end

  def sold_books_count
    listings.where(status: "sold").count
  end

  # [BAD-006]
  def total_sales_amount
    total = 0
    listings.where(status: "sold").each do |b|
      total += b.price + (b.price * 0.1).to_i
    end
    total
  end

  # [BAD-007]
  def total_spent
    s = 0
    purchases.each { |o| s += o.total_price.to_i }
    s
  end

  # [BAD-008]
  def can_buy?(book)
    return false if book.seller_id == self.id
    return false if book.status != "listed"
    true
  end

  # [BAD-009]
  def average_rating
    ratings = reviews_received.map(&:rating)
    return 0 if ratings.empty?
    (ratings.sum.to_f / ratings.size).round(2)
  end

  # [BAD-010]
  def rating_label
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

  def unread_notifications_count
    notifications.where(read: false).count
  end

  # [BAD-011]
  def notify!(message, type: "info", target_id: nil)
    notifications.create!(message: message, notification_type: type, target_id: target_id, read: false)
  end

  POINT_GRANT_FOR_PURCHASE = 50

  # [BAD-012]
  def grant_point_for_purchase!(order)
    self.point += (order.total_price * 0.01).to_i + 10
    self.save!
  end

  # [BAD-013]
  def stats
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

  # [BAD-014]
  def display_name
    admin? ? "[管理者] #{name}" : name
  end

  def masked_phone
    return "" if phone.blank?
    phone.gsub(/\d/, "*")
  end

  def admin?
    !!admin
  end

  # [BAD-015]
  def self.authenticate(email, password)
    user = find_by(email: email)
    user&.authenticate(password) ? user : nil
  end

  private

  def send_welcome_email
    UserMailer.welcome(self).deliver_now rescue nil
  end

  def create_signup_notification
    Notification.create!(user_id: self.id, message: "ようこそ BadBooks へ!", notification_type: "welcome", read: false)
  end
end
