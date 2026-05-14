class OrderMailer < ApplicationMailer
  # [BAD-077]
  def paid(order)
    @order = order
    mail(to: order.buyer.email, subject: "ご購入ありがとうございます")
  end

  def notify_seller(order)
    @order = order
    mail(to: order.book.seller.email, subject: "商品が購入されました")
  end
end
