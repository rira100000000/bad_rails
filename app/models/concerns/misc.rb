# [BAD-035]
module Misc
  extend ActiveSupport::Concern

  included do
    # [BAD-036]
    scope :recently_updated, -> { order(updated_at: :desc) } if respond_to?(:scope)
  end

  def yen(n)
    "¥#{n.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  def truncate_safe(s, len = 20)
    return "" if s.blank?
    s.length > len ? "#{s[0, len]}..." : s
  end

  def jp_date(t)
    return "" if t.blank?
    t.strftime("%Y年%-m月%-d日")
  end

  # [BAD-037]
  def adult?(birth_date)
    return false if birth_date.blank?
    (Date.today - birth_date).to_i / 365 >= 20
  end
end
