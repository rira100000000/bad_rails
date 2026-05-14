class Notification < ApplicationRecord
  belongs_to :user

  validates :message, presence: true

  scope :unread, -> { where(read: false) }
end
