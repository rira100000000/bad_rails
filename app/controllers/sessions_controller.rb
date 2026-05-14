class SessionsController < ApplicationController
  skip_before_action :require_login

  def new
  end

  def create
    # [BAD-044]
    user = User.find_by(email: params[:email])
    if user.nil?
      # [BAD-045]
      flash.now[:alert] = "そのメールアドレスは登録されていません"
      render :new, status: :unprocessable_entity
      return
    end
    if user.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = "ログインしました"
      redirect_to root_path
    else
      # [BAD-045]
      flash.now[:alert] = "パスワードが違います"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    flash[:notice] = "ログアウトしました"
    redirect_to root_path
  end
end
