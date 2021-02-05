class TwoFactorsToken < ApplicationRecord
  belongs_to :user

  scope :active, -> do
    where("created_at >= ?", 30.days.ago)
  end

  # expires when created at date is earlier than the date 30 days ago
  scope :expired, -> do
    where("created_at < ?", 30.days.ago)
  end
end
