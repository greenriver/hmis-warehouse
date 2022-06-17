###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Hmis::Eccovia::Assessment < GrdaWarehouseBase
    self.table_name = :eccovia_assessments
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    acts_as_paranoid

    def self.fetch_updated(data_source_id:, credentials:, since:)
    end
  end
end
