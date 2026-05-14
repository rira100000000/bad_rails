# [BAD-038]
class ApplicationController < ActionController::Base
  # [BAD-039]
  self.raise_on_missing_callback_actions = false if respond_to?(:raise_on_missing_callback_actions=)

  helper_method :current_user, :logged_in?, :calc_total_with_tax, :calc_shipping_fee

  # [BAD-040]
  before_action :require_login, except: [:index, :show, :new, :create]

  private

  # [BAD-041]
  def current_user
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

  # [BAD-042]
  def calc_total_with_tax(amount)
    (amount * 1.1).to_i
  end

  # [BAD-043]
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
