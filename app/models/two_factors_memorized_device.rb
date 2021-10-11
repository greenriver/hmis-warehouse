class TwoFactorsMemorizedDevice < ApplicationRecord
  belongs_to :user, optional: true

  scope :active, -> do
    where(arel_table[:expires_at].gt(Time.current))
  end

  # expires when created at date is earlier than the date 30 days ago
  scope :expired, -> do
    where(arel_table[:expires_at].lteq(Time.current))
  end

  def self.expiration_timestamp
    return Time.current unless GrdaWarehouse::Config.get(:bypass_2fa_duration)&.positive?
    GrdaWarehouse::Config.get(:bypass_2fa_duration).days.from_now
  end
end
