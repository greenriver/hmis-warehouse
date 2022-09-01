###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Loader
  class Client < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HmisStructure::Client
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2020_clients'

    # def self.clean_row_for_import(row, deidentified:)
    #   row = klass.deidentify_client_name(row) if deidentified
    #   row['SSN'] = row['SSN'].to_s[0..8] # limit SSNs to 9 characters
    #   row
    # end
  end
end
