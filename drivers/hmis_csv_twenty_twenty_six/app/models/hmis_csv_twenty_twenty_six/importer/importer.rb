###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Importer
  class Importer < HmisCsvImporter::Importer::Importer
    def initialize(**kwargs)
      super(**kwargs)
    end

    private def importable_files
      HmisCsvTwentyTwentySix.importable_files
    end

    private def ingest!
      super

      # Process custom augmentations and key-value stores after standard overlay
      process_custom_files!
    end

    private def process_custom_files!
      HmisCsvTwentyTwentySix.custom_files_config.custom_files.each do |file_config|
        filename = file_config['filename']
        next unless importable_files[filename]

        klass = importable_files[filename]
        Rails.logger.info "Processing custom file: #{filename}"

        if file_config['key_value_store']
          process_key_value_store(klass, file_config)
        elsif file_config['augments_warehouse_table']
          # Augmentations are handled natively by the importer
          # process_augmentation(klass, file_config)
        end
      end
    end

    private def process_key_value_store(klass, file_config)
      source_records = klass.incoming_data(importer_log_id: importer_log.id)
      HmisCsvTwentyTwentySix::Importer::ColumnMapper.process_key_value_store(
        source_records,
        file_config,
        importer_log,
      )
    end

    private def process_augmentation(klass, file_config)
      klass.incoming_data(importer_log_id: importer_log.id).find_each(batch_size: SELECT_BATCH_SIZE) do |row|
        augmented_record = row.as_destination_record
        next unless augmented_record&.changed?

        # Save the augmented warehouse record
        augmented_record.save!

        # Mark client demographics as dirty if we updated client
        augmented_record.update(demographic_dirty: true) if file_config['augments_warehouse_table'] == 'GrdaWarehouse::Hud::Client'
      end
    end
  end
end
