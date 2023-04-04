###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class RemoteCredential < GrdaWarehouseBase
    acts_as_paranoid
    attr_encrypted :password, key: ENV['ENCRYPTION_KEY'][0..31]

    scope :active, -> do
      where(active: true)
    end
  end
end
