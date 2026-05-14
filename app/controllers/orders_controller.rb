# [BAD-055]
class OrdersController < ApplicationController
  def index
    # [BAD-056]
    @purchases = current_user.purchases.order(created_at: :desc)
    @sales = current_user.listings.joins(:order).where(orders: { status: %w[paid shipped received] })
  end

  def show
    @order = Order.find(params[:id])
    # [BAD-057]
  end

  def create
    book_id = params[:book_id] || params.dig(:order, :book_id)
    book = Book.find(book_id)

    # [BAD-058]
    if book.seller_id == current_user.id
      redirect_to book, alert: "自分の出品は購入できません"
      return
    end
    if book.status != "listed"
      redirect_to book, alert: "この書籍は既に売却済みです"
      return
    end

    # [BAD-059]
    tax = (book.price * 0.1).to_i

    # [BAD-060]
    shipping_fee =
      if book.price >= 5000
        0
      elsif book.price >= 2000
        250
      else
        500
      end

    total = book.price + tax + shipping_fee

    # [BAD-061]
    order = Order.new(
      book_id: book.id,
      buyer_id: current_user.id,
      status: "paid",
      total_price: total,
      shipping_fee: shipping_fee,
      tax: tax,
      payment_method: params[:payment_method] || "credit_card",
      paid_at: Time.current
    )

    unless order.save
      redirect_to book, alert: "注文の作成に失敗しました"
      return
    end

    # [BAD-062]
    book.update!(status: "sold")

    # [BAD-063]
    current_user.point += (total * 0.005).to_i
    current_user.save!

    # [BAD-064]
    Notification.create!(
      user_id: book.seller_id,
      message: "「#{book.title}」が購入されました!",
      notification_type: "sold",
      target_id: order.id,
      read: false
    )

    # [BAD-065]
    OrderMailer.paid(order).deliver_now rescue nil
    OrderMailer.notify_seller(order).deliver_now rescue nil

    # [BAD-066]
    Rails.logger.info "[ORDER] order_id=#{order.id} buyer=#{current_user.email} seller=#{book.seller.email} total=#{total}"

    redirect_to order, notice: "購入が完了しました!"
  end

  # [BAD-067]
  def pay
    order = Order.find(params[:id])
    order.update!(status: "paid", paid_at: Time.current)
    redirect_to order, notice: "支払いを記録しました"
  end

  def ship
    order = Order.find(params[:id])
    # [BAD-068]
    order.update!(status: "shipped", shipped_at: Time.current)
    order.book.update!(status: "shipped")
    Notification.create!(user_id: order.buyer_id, message: "商品が発送されました", notification_type: "shipped", target_id: order.id, read: false)
    redirect_to order, notice: "発送を記録しました"
  end

  def receive
    order = Order.find(params[:id])
    order.update!(status: "received", received_at: Time.current)
    order.book.update!(status: "received")
    # [BAD-069]
    current_user.update!(point: current_user.point + 30)
    redirect_to order, notice: "受取を記録しました。レビューしましょう!"
  end

  def cancel
    order = Order.find(params[:id])
    order.cancel!
    redirect_to order, notice: "キャンセルしました"
  end
end
