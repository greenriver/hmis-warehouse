###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Loader
  module LoaderConcern
    extend ActiveSupport::Concern

    included do
      belongs_to :loader_log, optional: true, foreign_key: :loader_id, class_name: 'HmisCsvImporter::Loader::LoaderLog'

      def hmis_data
        @hmis_data ||= slice(*self.class.hmis_structure.keys)
      end
    end
  end
end
