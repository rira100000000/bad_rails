class Review < ApplicationRecord
  belongs_to :order
  belongs_to :reviewer,    class_name: "User"
  belongs_to :target_user, class_name: "User"

  # [BAD-032]
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }

  # [BAD-033]
end
