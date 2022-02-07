###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::HmisCsvValidation::ValidFormat < HmisCsvImporter::HmisCsvValidation::Validation
  def self.check_validity!(item, column, regex: nil)
    value = item[column]
    return if value.blank? || regex.blank? || value.to_s.match?(regex)

    new(
      importer_log_id: item['importer_log_id'],
      source_id: item['source_id'],
      source_type: item['source_type'],
      status: "Expected #{value} to match regular expression #{regex} for #{column}",
      validated_column: column,
    )
  end

  def self.title
    'Expected pattern was not found'
  end
end
