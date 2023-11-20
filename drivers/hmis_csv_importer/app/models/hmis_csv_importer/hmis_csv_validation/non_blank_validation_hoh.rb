###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::HmisCsvValidation::NonBlankValidationHoh < HmisCsvImporter::HmisCsvValidation::Validation
  def self.check_validity!(item, column)
    value = item[column]
    return if value.present?
    return unless item['RelationshipToHoH'] == 1

    new(
      importer_log_id: item['importer_log_id'],
      source_id: item['source_id'],
      source_type: item['source_type'],
      status: "A value is required for #{column}",
      validated_column: column,
    )
  end

  def self.title
    'Missing required value for HoH'
  end
end
