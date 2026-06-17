###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentyFour::Loader
  class Client < GrdaWarehouse::Hud::Base
    include LoaderConcern
    include ::HmisStructure::Client
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2024_clients'
    self.primary_key = 'id'
  end
end
