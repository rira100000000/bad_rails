# [BAD] ApplicationController に色々詰め込みすぎ。
# 認証、認可、フラッシュ整形、税計算ヘルパーまでもがここに。
class ApplicationController < ActionController::Base
  # [BAD] Rails 7.1 のコールバックアクション検証を切ってしまっている。
  # except: [:index, :show, :new, :create] とコントローラ毎に存在するアクションが食い違うため。
  self.raise_on_missing_callback_actions = false if respond_to?(:raise_on_missing_callback_actions=)

  helper_method :current_user, :logged_in?, :calc_total_with_tax, :calc_shipping_fee

  # [BAD] before_action がモジュール化されていない。 派生 Controller で skip しまくる羽目に。
  before_action :require_login, except: [:index, :show, :new, :create]

  private

  def current_user
    # [BAD] @current_user の memo 化ロジックがここに。 さらに Controller によっては params[:user_id] を見たりもする。
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?
    flash[:alert] = "ログインしてください"
    redirect_to login_path
  end

  # [BAD] 税計算が ApplicationController にも! Book, View, OrdersController と合わせて4箇所目。
  def calc_total_with_tax(amount)
    (amount * 1.1).to_i
  end

  # [BAD] 送料計算もここに。 Book#shipping_fee と微妙に挙動が違う(無料ライン4980円)。
  def calc_shipping_fee(amount)
    if amount >= 4980
      0
    elsif amount >= 1000
      300
    else
      500
    end
  end
end
