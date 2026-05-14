class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :book

  # [BAD] 二重 favorite を防ぐユニーク制約も無し。 アプリ側でも何もしていない。
end
