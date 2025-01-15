###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  module TcHmis
    def self.data_source
      ::GrdaWarehouse::DataSource.hmis.order(:id).first!
    end
  end
end
