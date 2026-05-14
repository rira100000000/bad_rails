# [BAD-026]
class Order < ApplicationRecord
  belongs_to :book
  belongs_to :buyer, class_name: "User"
  has_one  :review, dependent: :nullify

  STATUSES = %w[pending paid shipped received cancelled].freeze

  validates :status, inclusion: { in: STATUSES }

  # [BAD-027]
  scope :paid,     -> { where(status: "paid") }
  scope :shipped,  -> { where(status: "shipped") }
  scope :received, -> { where(status: "received") }

  # [BAD-028]
  after_create :send_paid_email
  # [BAD-029]
  after_create :create_buyer_notification

  def seller
    book.seller
  end

  # [BAD-030]
  def reviewable?
    status == "received" && review.nil?
  end

  # [BAD-031]
  def cancel!
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
