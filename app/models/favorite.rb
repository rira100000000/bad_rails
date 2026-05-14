class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :book

  # [BAD-034]
end
