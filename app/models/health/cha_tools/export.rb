###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'kiba-common/destinations/csv'

module Health::ChaTools
  module Export
    module_function

    def setup(config)
      Kiba.parse do
        source Health::ChaTools::ChaSource

        destination Kiba::Common::Destinations::CSV, filename: config[:filename], csv_options: { force_quotes: true }
      end
    end
  end
end
