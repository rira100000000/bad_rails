# [BAD] The Fat Controller.
# 在庫(=status)チェック、決済、税計算、送料計算、ポイント付与、メール送信、通知、ログ出力を全部直書き。
# しかもトランザクションを張っていないので途中でコケたら不整合が出る。
class OrdersController < ApplicationController
  def index
    # [BAD] N+1 確定。 includes 無し。
    @purchases = current_user.purchases.order(created_at: :desc)
    @sales = current_user.listings.joins(:order).where(orders: { status: %w[paid shipped received] })
  end

  def show
    @order = Order.find(params[:id])
    # [BAD] 認可チェックなし。 注文IDが分かれば他人の注文も見える。
  end

  def create
    book_id = params[:book_id] || params.dig(:order, :book_id)
    book = Book.find(book_id)

    # [BAD] 認可・在庫チェック・状態チェックを if 文の山で。
    if book.seller_id == current_user.id
      redirect_to book, alert: "自分の出品は購入できません"
      return
    end
    if book.status != "listed"
      redirect_to book, alert: "この書籍は既に売却済みです"
      return
    end

    # [BAD] 税計算が Controller に登場。 Book#price_with_tax を呼べばいいのに、また直書き。
    tax = (book.price * 0.1).to_i

    # [BAD] 送料計算もここで再実装。 Book#shipping_fee, ApplicationController#calc_shipping_fee と挙動が微妙に違う。
    shipping_fee =
      if book.price >= 5000
        0
      elsif book.price >= 2000
        250  # [BAD] Book では 300円なのに、ここでは 250円。 ロジック乖離。
      else
        500
      end

    total = book.price + tax + shipping_fee

    # [BAD] トランザクション無し。 Order の作成と book の状態更新が別操作。
    order = Order.new(
      book_id: book.id,
      buyer_id: current_user.id,
      status: "paid",          # [BAD] 決済モック扱いで即 paid。 状態遷移メソッドを使わず直書き。
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

    # [BAD] Book の状態更新が Order の save と別。 ここで失敗するとデータ不整合。
    book.update!(status: "sold")

    # [BAD] ポイント付与もここに。 User#grant_point_for_purchase! と挙動が微妙に違う。
    current_user.point += (total * 0.005).to_i  # [BAD] User 側では 1% + 10、 ここでは 0.5%。
    current_user.save!

    # [BAD] 通知作成を直書き。 Order の after_create でも作っており、 重複通知が出る!
    Notification.create!(
      user_id: book.seller_id,
      message: "「#{book.title}」が購入されました!",
      notification_type: "sold",
      target_id: order.id,
      read: false
    )

    # [BAD] メール送信も同期で直書き。 SMTP がコケたら全部止まる。
    OrderMailer.paid(order).deliver_now rescue nil
    OrderMailer.notify_seller(order).deliver_now rescue nil

    # [BAD] ログ出力をベタで。 ログレベルも分けず、 個人情報を平文で出している。
    Rails.logger.info "[ORDER] order_id=#{order.id} buyer=#{current_user.email} seller=#{book.seller.email} total=#{total}"

    redirect_to order, notice: "購入が完了しました!"
  end

  def pay
    order = Order.find(params[:id])
    # [BAD] 既に paid なのに pay できるバグの余地。 状態遷移チェックなし。
    order.update!(status: "paid", paid_at: Time.current)
    redirect_to order, notice: "支払いを記録しました"
  end

  def ship
    order = Order.find(params[:id])
    # [BAD] 出荷できるのは seller のみのはずだが認可なし。
    order.update!(status: "shipped", shipped_at: Time.current)
    order.book.update!(status: "shipped")
    Notification.create!(user_id: order.buyer_id, message: "商品が発送されました", notification_type: "shipped", target_id: order.id, read: false)
    redirect_to order, notice: "発送を記録しました"
  end

  def receive
    order = Order.find(params[:id])
    order.update!(status: "received", received_at: Time.current)
    order.book.update!(status: "received")
    # [BAD] ポイント付与三度目の登場。 User#grant_point_for_purchase! と OrdersController#create と三重実装。
    current_user.update!(point: current_user.point + 30)
    redirect_to order, notice: "受取を記録しました。レビューしましょう!"
  end

  def cancel
    order = Order.find(params[:id])
    order.cancel!
    redirect_to order, notice: "キャンセルしました"
  end
end
