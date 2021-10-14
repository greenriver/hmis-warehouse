###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class VerificationSource < GrdaWarehouseBase
    self.table_name = :verification_sources
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true

    def title
      raise NotImplementedError
    end
  end
end
