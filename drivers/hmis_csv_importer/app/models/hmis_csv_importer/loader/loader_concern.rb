###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Loader
  module LoaderConcern
    extend ActiveSupport::Concern

    included do
      belongs_to :loader_log

      def hmis_data
        @hmis_data ||= slice(*self.class.hmis_structure.keys)
      end
    end
  end
end
