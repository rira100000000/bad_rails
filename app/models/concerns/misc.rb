# [BAD] "とりあえず共通っぽいもの" を集めただけの Concern。
# 全然関係ない処理が並んでいて、 include する側で何が混ざるか分からない。
# Concern の典型的なアンチパターン。
module Misc
  extend ActiveSupport::Concern

  included do
    # [BAD] include する側に勝手に scope を生やしてしまう。 副作用すぎる。
    scope :recently_updated, -> { order(updated_at: :desc) } if respond_to?(:scope)
  end

  # 数値整形(本来 Helper や Value Object)
  def yen(n)
    "¥#{n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  # 文字列処理
  def truncate_safe(s, len = 20)
    return "" if s.blank?
    s.length > len ? "#{s[0, len]}..." : s
  end

  # 日付整形
  def jp_date(t)
    return "" if t.blank?
    t.strftime("%Y年%-m月%-d日")
  end

  # [BAD] よく分からない判定。
  def adult?(birth_date)
    return false if birth_date.blank?
    (Date.today - birth_date).to_i / 365 >= 20
  end
end
