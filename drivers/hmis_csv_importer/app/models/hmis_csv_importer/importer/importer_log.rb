###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::Importer
  class ImporterLog < GrdaWarehouseBase
    include ActionView::Helpers::DateHelper
    self.table_name = 'hmis_csv_importer_logs'

    has_many :import_errors
    has_many :import_validations, class_name: 'HmisCsvImporter::HmisCsvValidation::Base'
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

    def paused?
      status.to_s == 'paused'
    end

    def resuming?
      status.to_s == 'resuming'
    end

    def import_time
      return unless persisted?
      # Historically we didn't set started_at
      return unless started_at

      if completed_at && started_at
        seconds = ((completed_at - started_at) / 1.minute).round * 60
        distance_of_time_in_words(seconds)
      else
        'processing...'
      end
    end

    def any_errors_or_validations?
      import_errors.exists? || import_validations.exists?
    end

    def import_validations_count(filename, files)
      validation_classes = HmisCsvImporter::HmisCsvValidation::Base.validation_classes.map(&:to_s)
      loader_class = files.to_h.invert[filename]
      import_validations.where(source_type: loader_class, type: validation_classes).count
    end

    def import_validation_errors_count(filename, files)
      error_classes = HmisCsvImporter::HmisCsvValidation::Base.error_classes.map(&:to_s)
      loader_class = files.to_h.invert[filename]
      import_validations.where(source_type: loader_class, type: error_classes).count
    end
  end
end
