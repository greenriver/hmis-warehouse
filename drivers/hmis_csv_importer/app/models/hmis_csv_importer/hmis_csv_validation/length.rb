###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::HmisCsvValidation::Length < HmisCsvImporter::HmisCsvValidation::Error
  def self.check_validity!(item, column, max:, min: 0)
    value = item[column].to_s
    return if value.size >= min && value.size <= max

    new(
      importer_log_id: item['importer_log_id'],
      source_id: item['source_id'],
      source_type: item['source_type'],
      status: "The length of #{column} must be in range #{min}..#{max}",
      validated_column: column,
    )
  end

  def self.title
    'Incorrect column length'
  end
end
