###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Loader
  class LoaderLog < GrdaWarehouseBase
    self.table_name = 'hmis_csv_loader_logs'
  end
end
