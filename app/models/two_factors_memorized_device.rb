class TwoFactorsMemorizedDevice < ApplicationRecord
  belongs_to :user

  after_create :record_expires_at

  scope :active, -> do
    where(arel_table[:expires_at].gt(Time.current))
  end

  # expires when created at date is earlier than the date 30 days ago
  scope :expired, -> do
    where(arel_table[:expires_at].lteq(Time.current))
  end

  def self.active_duration
    # FIXME use warehouse config
    30.days
  end

  private def record_expires_at
    self.expires_at = self.created_at + self.class.active_duration
    self.save!
  end
end
