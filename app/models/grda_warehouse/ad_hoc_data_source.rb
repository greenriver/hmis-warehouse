###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AdHocDataSource < GrdaWarehouseBase
  acts_as_paranoid

  validates_presence_of :name
  validates_presence_of :short_name

  CACHE_EXPIRY = if Rails.env.production? then 20.hours else 20.seconds end

  has_many :ad_hoc_batches
  has_many :ad_hoc_clients

  scope :active, -> do
    where(active: true)
  end

  scope :viewable_by, ->(user) do
    return all if user.can_manage_ad_hoc_data_sources?
    return where(user_id: user.id) if user.can_manage_own_ad_hoc_data_sources?

    none
  end

  def self.blank_csv
    [
      'First Name,Middle Name,Last Name,SSN,DOB',
      'First,Middle,Last,000-00-000,2000-01-30',
    ]
  end
end
