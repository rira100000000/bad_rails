class BooksController < ApplicationController
  skip_before_action :require_login, only: [:index, :show]

  def index
    # [BAD-048]
    @books = Book.where(status: "listed")
    if params[:q].present?
      q = params[:q]
      @books = @books.where("title LIKE '%#{q}%' OR author LIKE '%#{q}%' OR description LIKE '%#{q}%'")
    end
    if params[:category_id].present?
      @books = @books.where(category_id: params[:category_id])
    end
    if params[:min_price].present?
      @books = @books.where("price >= ?", params[:min_price].to_i)
    end
    if params[:max_price].present?
      @books = @books.where("price <= ?", params[:max_price].to_i)
    end
    @books = @books.order(created_at: :desc)
    # [BAD-049]
    @categories = Category.all
  end

  def show
    @book = Book.find(params[:id])
    @favorited = logged_in? && current_user.favorites.exists?(book_id: @book.id)
  end

  def new
    @book = Book.new
    @categories = Category.all
  end

  def create
    # [BAD-050]
    attrs = params[:book].to_unsafe_h
    attrs[:seller_id] = current_user.id if attrs[:seller_id].blank?
    @book = Book.new(attrs)
    if @book.save
      flash[:notice] = "出品しました"
      redirect_to @book
    else
      @categories = Category.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @book = Book.find(params[:id])
    # [BAD-051]
    @categories = Category.all
  end

  def update
    @book = Book.find(params[:id])
    # [BAD-051]
    if @book.update(params[:book].to_unsafe_h)
      flash[:notice] = "更新しました"
      redirect_to @book
    else
      @categories = Category.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @book = Book.find(params[:id])
    # [BAD-051]
    @book.destroy
    redirect_to books_path, notice: "削除しました"
  end

  def favorite
    book = Book.find(params[:id])
    # [BAD-052]
    current_user.favorites.create!(book_id: book.id)
    redirect_to book, notice: "お気に入りに追加しました"
  end

  def unfavorite
    book = Book.find(params[:id])
    current_user.favorites.where(book_id: book.id).destroy_all
    redirect_to book, notice: "お気に入りを外しました"
  end

  # [BAD-053]
  def buy
    book = Book.find(params[:id])
    if book.seller_id == current_user.id || book.status != "listed"
      redirect_to book, alert: "購入できません" and return
    end
    # [BAD-054]
    tax = (book.price * 0.08).to_i
    shipping = book.price >= 3000 ? 0 : 400
    total = book.price + tax + shipping
    order = Order.create!(
      book_id: book.id, buyer_id: current_user.id,
      status: "paid", total_price: total, tax: tax, shipping_fee: shipping,
      payment_method: "credit_card", paid_at: Time.current
    )
    book.update!(status: "sold")
    redirect_to order, notice: "購入完了"
  end
end
