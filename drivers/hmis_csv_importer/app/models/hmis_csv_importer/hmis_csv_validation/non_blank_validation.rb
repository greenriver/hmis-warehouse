###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisCsvImporter::HmisCsvValidation::NonBlankValidation < HmisCsvImporter::HmisCsvValidation::Validation
  def self.check_validity!(item, column, constraint_lambda: nil)
    value = item[column]
    return if value.present?

    # If any constraints are provided, check if they are met before adding a validation error
    return if constraint_lambda.present? && constraint_lambda.call(item)

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
