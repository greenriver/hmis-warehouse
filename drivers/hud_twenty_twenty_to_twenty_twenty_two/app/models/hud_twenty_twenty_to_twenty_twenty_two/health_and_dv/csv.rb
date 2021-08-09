###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'kiba-common/sources/csv'
require 'kiba-common/destinations/csv'

module HudTwentyTwentyToTwentyTwentyTwo::HealthAndDv::Csv
  module_function

  def up(source_name, destination_name)
    HudTwentyTwentyToTwentyTwentyTwo::HealthAndDv::Transform.up(
      Kiba::Common::Sources::CSV,
      {
        filename: source_name,
        csv_options: {
          headers: :first_row,
          skip_blanks: true,
        },
      },
      Kiba::Common::Destinations::CSV,
      {
        filename: destination_name,
        headers: GrdaWarehouse::Hud::HealthAndDv.hmis_configuration(version: '2022').keys.map(&:to_s),
      },
    )
  end
end
