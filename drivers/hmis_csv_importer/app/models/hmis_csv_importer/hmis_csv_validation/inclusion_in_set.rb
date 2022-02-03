###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::HmisCsvValidation::InclusionInSet < HmisCsvImporter::HmisCsvValidation::Validation
  def self.check_validity!(item, column, valid_options: nil)
    value = item[column]
    return if value.blank? || value.to_s.in?(valid_options)

    new(
      importer_log_id: item['importer_log_id'],
      source_id: item['source_id'],
      source_type: item['source_type'],
      status: "Expected #{value} to be included in #{short_list(valid_options)} for #{column}",
      validated_column: column,
    )
  end

  def self.short_list(options)
    return options if options.length < 10

    options[0..9] + ['...']
  end

  def self.title
    'Inclusion in specific set'
  end
end
