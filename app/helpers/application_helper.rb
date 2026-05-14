# [BAD] ApplicationHelper を "便利関数置き場" として使ってしまっている。
# helper の責務分割がされていない典型例。
module ApplicationHelper
  # [BAD] 価格整形は Book#display_price や view 内 ERB 文字列補間と三重実装。
  def yen(n)
    return "" if n.blank?
    "¥#{n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  # [BAD] 税計算ヘルパー。 これで税計算ロジックは5箇所目!
  def with_tax(amount)
    (amount.to_i * 1.1).to_i
  end

  # [BAD] ステータスを表示する場所がここにも。 Book#status_label と二重実装。
  def book_status_label(status)
    {
      "listed"    => "出品中",
      "sold"      => "売却済",
      "shipped"   => "発送済",
      "received"  => "受取完了",
      "cancelled" => "キャンセル"
    }[status] || status
  end

  # [BAD] そもそも認可ロジックを view から呼べてしまう。
  def can_edit_book?(book)
    return false unless current_user
    current_user.id == book.seller_id || current_user.admin?
  end

  # [BAD] DB アクセスがヘルパーに! View 描画中に SQL が飛ぶ。
  def unread_count_for(user)
    Notification.where(user_id: user.id, read: false).count
  end
end
