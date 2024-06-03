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

      if respond_to?(:hud_key)
        name.demodulize.tap do |class_name |
          has_one :destination_record_with_deleted, -> { with_deleted }, **hud_assoc(hud_key, class_name)
        end
      end

      def hmis_data
        @hmis_data ||= slice(*self.class.hmis_structure.keys)
      end
    end
  end
end
