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

  private def record_expires_at
    self.expires_at = self.created_at + GrdaWarehouse::Config.get(:bypass_2fa_duration).days
    self.save!
  end
end
