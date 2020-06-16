###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Loader
  class LoaderLog < GrdaWarehouseBase
    include HmisTwentyTwenty

    self.table_name = 'hmis_csv_loader_logs'
    has_many :load_errors

    def self.module_scope
      'HmisCsvTwentyTwenty::Loader'
    end
  end
end
