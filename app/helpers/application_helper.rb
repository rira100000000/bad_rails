# [BAD-071]
module ApplicationHelper
  # [BAD-072]
  def yen(n)
    return "" if n.blank?
    "¥#{n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  # [BAD-073]
  def with_tax(amount)
    (amount.to_i * 1.1).to_i
  end

  # [BAD-074]
  def book_status_label(status)
    {
      "listed"    => "出品中",
      "sold"      => "売却済",
      "shipped"   => "発送済",
      "received"  => "受取完了",
      "cancelled" => "キャンセル"
    }[status] || status
  end

  # [BAD-075]
  def can_edit_book?(book)
    return false unless current_user
    current_user.id == book.seller_id || current_user.admin?
  end

  # [BAD-076]
  def unread_count_for(user)
    Notification.where(user_id: user.id, read: false).count
  end
end
