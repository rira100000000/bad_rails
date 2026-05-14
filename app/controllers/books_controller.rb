class BooksController < ApplicationController
  skip_before_action :require_login, only: [:index, :show]

  def index
    # [BAD] 検索条件の組み立てを Controller で文字列補間。 SQL Injection の余地。
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
    # [BAD] includes してない → view で N+1 確定。
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
    # [BAD] strong params なし。 seller_id を params から渡されると別ユーザに偽装可能。
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
    # [BAD] 認可チェックがない。 他人の出品も編集できる。
    @categories = Category.all
  end

  def update
    @book = Book.find(params[:id])
    # [BAD] こちらも認可なし & strong params なし。
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
    @book.destroy
    redirect_to books_path, notice: "削除しました"
  end

  def favorite
    book = Book.find(params[:id])
    # [BAD] 重複登録チェックなし。 何度でも favorite できてしまう。
    current_user.favorites.create!(book_id: book.id)
    redirect_to book, notice: "お気に入りに追加しました"
  end

  def unfavorite
    book = Book.find(params[:id])
    current_user.favorites.where(book_id: book.id).destroy_all
    redirect_to book, notice: "お気に入りを外しました"
  end

  # [BAD] このアクションが OrdersController#create とほぼ同じ処理をしている。
  # しかも税計算・送料計算・通知作成のロジックが OrdersController と微妙に違う。
  def buy
    book = Book.find(params[:id])
    if book.seller_id == current_user.id || book.status != "listed"
      redirect_to book, alert: "購入できません" and return
    end
    # [BAD] 税率・送料が OrdersController#create と異なる。 結果、buy 経由と orders#create 経由で金額が変わる。
    tax = (book.price * 0.08).to_i  # [BAD] 8%! OrdersController は 10%。
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
