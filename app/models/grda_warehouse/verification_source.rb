###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class VerificationSource < GrdaWarehouseBase
    self.table_name = :verification_sources
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'

    def title
      raise NotImplementedError
    end
  end
end