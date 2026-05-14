class Review < ApplicationRecord
  belongs_to :order
  belongs_to :reviewer,    class_name: "User"
  belongs_to :target_user, class_name: "User"

  # [BAD] rating の範囲はバリデーションで担保されているが、 view では `if rating == 5` のような分岐が散らかる。
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }

  # [BAD] after_create で評価サマリを集計しない。 結果、 User#average_rating が毎回フルスキャン。
end
