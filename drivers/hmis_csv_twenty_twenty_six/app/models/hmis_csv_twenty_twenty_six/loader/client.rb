###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Loader
  class Client < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HmisStructure::Client
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2026_clients'
    self.primary_key = 'id'

    # HUD removed an e in FY2026, rather than change the column name, we'll alias it
    def self.column_name_for_import(column_name)
      case column_name.to_s
      when 'HispanicLatinao'
        'HispanicLatinaeo'
      else
        column_name
      end
    end
  end
end
