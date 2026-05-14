# [BAD] login 失敗時のメッセージが具体的すぎる(セキュリティ的にも問題)。
class SessionsController < ApplicationController
  skip_before_action :require_login

  def new
  end

  def create
    # [BAD] User.authenticate は使わず find_by + authenticate を直書き。 重複した認証経路。
    user = User.find_by(email: params[:email])
    if user.nil?
      flash.now[:alert] = "そのメールアドレスは登録されていません"
      render :new, status: :unprocessable_entity
      return
    end
    if user.authenticate(params[:password])
      session[:user_id] = user.id
      flash[:notice] = "ログインしました"
      redirect_to root_path
    else
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
