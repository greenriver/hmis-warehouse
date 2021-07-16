###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#

require 'kiba-common/sources/csv'
require 'kiba-common/destinations/csv'

module HudTwentyTwentyToTwentyTwentyTwo::Export
  module_function

  def up(source_name, destination_name)
    Kiba.parse do
      source Kiba::Common::Sources::CSV,
             filename: source_name,
             csv_options: {
               headers: :first_row,
               skip_blanks: true,
             }

      transform(&:to_hash)
      transform AddCsvVersionToExport

      destination Kiba::Common::Destinations::CSV,
                  filename: destination_name,
                  headers: GrdaWarehouse::Hud::Export.hmis_configuration(version: '2022').keys.map(&:to_s)
    end
  end

  def down(source_name, destination_name)
    Kiba.parse do
      source Kiba::Common::Sources::CSV,
             filename: source_name,
             csv_options: {
               headers: :first_row,
               skip_blanks: true,
             }

      transform(&:to_hash)

      destination Kiba::Common::Destinations::CSV,
                  filename: destination_name,
                  headers: GrdaWarehouse::Hud::Export.hmis_configuration(version: '2020').keys.map(&:to_s)
    end
  end
end
