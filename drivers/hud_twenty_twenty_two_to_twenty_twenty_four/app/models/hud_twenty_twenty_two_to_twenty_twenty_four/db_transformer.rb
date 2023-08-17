###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudTwentyTwentyTwoToTwentyTwentyFour
  class DbTransformer
    def self.up
      classes = [
        HudTwentyTwentyToTwentyTwentyTwo::Export::Db,
      ]
      # classes << HudTwentyTwentyToTwentyTwentyTwo::AggregatedEnrollment::Db if RailsDrivers.loaded.include?(:hmis_csv_importer)

      classes.each do |klass|
        puts klass
        ::Kiba.run(klass.up)
      end
    end
  end
end
