class UsersController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
    @user = User.new
  end

  def create
    # [BAD-046]
    @user = User.new(params[:user].permit!)
    if @user.save
      session[:user_id] = @user.id
      flash[:notice] = "登録しました"
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @user = User.find(params[:id])
    # [BAD-047]
    @listings = @user.listings.order(created_at: :desc)
    @stats = @user.stats
  end
end
