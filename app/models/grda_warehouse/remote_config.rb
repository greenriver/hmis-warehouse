###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class RemoteConfig < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :remote_credential
    scope :active, -> do
      where(active: true)
    end
  end
end
