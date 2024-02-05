###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::HmisCsvValidation::NonBlank < HmisCsvImporter::HmisCsvValidation::Error
  def self.check_validity!(item, column)
    value = item[column]
    return if value.present?

    # The ForcePrioritizedPlacementStatus import hook will fix blank PrioritizationStatus, but because this field is null false, we need to skip that check if the hook is enabled.
    if item['source_type'] == 'HmisCsvTwentyTwentyFour::Loader::Assessment' && column.to_sym == :PrioritizationStatus
      force_prioritized_placement_enabled = Rails.cache.fetch(['HmisCsvImporter::HmisCsvCleanup::ForcePrioritizedPlacementStatus', item['data_source_id'].to_i], expires_in: 5.minutes) do
        data_source = GrdaWarehouse::DataSource.find(item['data_source_id'].to_i)
        data_source.import_cleanups.key?('Assessment') && data_source.import_cleanups['Assessment'].include?('HmisCsvImporter::HmisCsvCleanup::ForcePrioritizedPlacementStatus')
      end
      return if force_prioritized_placement_enabled
    end

    new(
      importer_log_id: item['importer_log_id'],
      source_id: item['source_id'],
      source_type: item['source_type'],
      status: "A value is required for #{column}",
      validated_column: column,
    )
  end

  def self.title
    'Missing required value'
  end
end
