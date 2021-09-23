###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::GrdaWarehouse
  module ImportLogExtension
    extend ActiveSupport::Concern

    included do
      belongs_to :importer_log, class_name: 'HmisCsvImporter::Importer::ImporterLog', optional: true
      belongs_to :loader_log, class_name: 'HmisCsvImporter::Loader::LoaderLog', optional: true

      def import_time(details: false)
        return unless persisted?

        if completed_at.present?
          return 'Paused for error review' if has_attribute?('importer_log_id') && importer_log&.paused?

          seconds = ((completed_at - created_at) / 1.minute).round * 60
          distance_of_time_in_words(seconds)
        elsif upload.present?
          upload.import_time(details: details)
        else
          return 'failed' if updated_at < 2.days.ago

          'processing...'
        end
      end
    end
  end
end
