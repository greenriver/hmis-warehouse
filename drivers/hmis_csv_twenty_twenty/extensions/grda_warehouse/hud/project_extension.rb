###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::GrdaWarehouse::Hud
  module ProjectExtension
    extend ActiveSupport::Concern

    included do
      def convert_to_aggregated!
        data_source.update(
          import_aggregators: {
            'Exit' => ['HmisCsvTwentyTwenty::Aggregated::FilterExits'],
            'Enrollment' => ['HmisCsvTwentyTwenty::Aggregated::CombineEnrollments'],
          },
        )
        update(combine_enrollments: true)
      end
    end
  end
end
