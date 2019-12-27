###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::AdHocDataSource < GrdaWarehouseBase
  acts_as_paranoid

  validates :name, presence: true
  validates :short_name, presence: true

  CACHE_EXPIRY = if Rails.env.production? then 20.hours else 20.seconds end

  has_many :ad_hoc_batches
  has_many :ad_hoc_clients

  scope :active, -> do
    where(active: true)
  end

  scope :viewable_by, -> (user) do
    return all if user.can_manage_ad_hoc_data_sources?
    none
  end

end
