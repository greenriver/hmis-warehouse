###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HMIS2020
  class User < GrdaWarehouse::Hud::User
    include ::Import::HMIS2020::Shared
    include TsqlImport
    self.hud_key = :UserID
    setup_hud_column_access( GrdaWarehouse::Hud::User.hud_csv_headers(version: '2020') )

    def self.file_name
      'User.csv'
    end

  end
end