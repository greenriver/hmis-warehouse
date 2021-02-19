###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Loader
  module LoaderConcern
    extend ActiveSupport::Concern

    included do
      belongs_to :loader_log, optional: true

      def hmis_data
        @hmis_data ||= slice(*self.class.hmis_structure(version: '2020').keys)
      end
    end
  end
end
