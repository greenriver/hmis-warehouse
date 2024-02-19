###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'kiba-common/sources/csv'
require 'kiba-common/destinations/csv'

module HudTwentyTwentyToTwentyTwentyTwo::Kiba::CsvBase
  extend ActiveSupport::Concern

  included do
    def self.up(source_name, destination_name, encoding, header_converter)
      HudTwentyTwentyToTwentyTwentyTwo::Kiba::Transform.up(
        Kiba::Common::Sources::CSV,
        {
          filename: source_name,
          csv_options: {
            headers: :first_row,
            skip_blanks: true,
            liberal_parsing: true,
            header_converters: header_converter,
            encoding: encoding,
          },
        },
        transforms(csv: true),
        Kiba::Common::Destinations::CSV,
        {
          filename: destination_name,
          headers: target_class.hmis_configuration(version: '2022').keys.map(&:to_s),
        },
      )
    end
  end
end
