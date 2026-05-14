# [BAD] Order だけど、 ほとんどのロジックは OrdersController に逃げている。
# 一方で状態管理メソッドはここにもあり、Controller と二重実装。
class Order < ApplicationRecord
  belongs_to :book
  belongs_to :buyer, class_name: "User"
  has_one  :review, dependent: :nullify

  STATUSES = %w[pending paid shipped received cancelled].freeze

  validates :status, inclusion: { in: STATUSES }

  # [BAD] スコープと文字列リテラルが混在。 controller 側でも status 文字列を直書き比較。
  scope :paid,     -> { where(status: "paid") }
  scope :shipped,  -> { where(status: "shipped") }
  scope :received, -> { where(status: "received") }

  # [BAD] after_create で副作用が走る。 トランザクション境界が曖昧。
  after_create :send_paid_email
  after_create :create_buyer_notification

  def seller
    book.seller
  end

  def reviewable?
    # [BAD] reviewable? が複数の場所に散らかっている(View, Controller, Model)。
    status == "received" && review.nil?
  end

  def cancel!
    # [BAD] cancel するときに book を listed に戻す。 トランザクション無し。
    self.status = "cancelled"
    self.save!
    book.update!(status: "listed")
  end

  private

  def send_paid_email
    OrderMailer.paid(self).deliver_now rescue nil
  end

  def create_buyer_notification
    Notification.create!(
      user_id: buyer_id,
      message: "「#{book.title}」を購入しました。発送をお待ちください。",
      notification_type: "order_created",
      target_id: id,
      read: false
    )
  end
end
