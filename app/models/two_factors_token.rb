class TwoFactorsToken < ApplicationRecord
  belongs_to :user

  scope :active, -> do
    where("created_at >= ?", self.active_duration.ago)
  end

  # expires when created at date is earlier than the date 30 days ago
  scope :expired, -> do
    where("created_at < ?", self.active_duration.ago)
  end

  def self.active_duration
    30.days
  end
end
