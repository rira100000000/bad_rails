class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications.order(created_at: :desc)
  end

  def read
    n = current_user.notifications.find(params[:id])
    n.update!(read: true)
    redirect_to notifications_path
  end
end
