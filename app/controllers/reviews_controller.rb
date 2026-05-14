class ReviewsController < ApplicationController
  def new
    @order = Order.find(params[:order_id])
    @review = Review.new
  end

  def create
    order = Order.find(params[:order_id])
    # [BAD] 認可も状態チェックも無い。 received でない注文にもレビューが書ける。
    review = Review.new(
      order_id: order.id,
      reviewer_id: current_user.id,
      target_user_id: order.book.seller_id,
      rating: params[:review][:rating].to_i,
      comment: params[:review][:comment]
    )
    if review.save
      redirect_to order, notice: "レビューを投稿しました"
    else
      redirect_to new_review_path(order_id: order.id), alert: review.errors.full_messages.to_sentence
    end
  end
end
