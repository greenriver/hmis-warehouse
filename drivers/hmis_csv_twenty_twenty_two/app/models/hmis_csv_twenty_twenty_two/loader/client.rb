###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentyTwo::Loader
  class Client < GrdaWarehouse::Hud::Base
    def self.skip_hispanic_alias? = true
    include LoaderConcern
    include ::HmisStructure::Client
    # Because GrdaWarehouse::Hud::* defines the table name, we can't use table_name_prefix :(
    self.table_name = 'hmis_csv_2022_clients'
    self.primary_key = 'id'
  end
end
