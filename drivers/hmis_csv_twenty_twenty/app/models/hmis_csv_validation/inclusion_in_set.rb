###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvValidation::InclusionInSet < HmisCsvValidation::Validation
  def self.check_validity!(item, column, valid_options: nil)
    value = item[column]
    return if value.blank? || value.to_s.in?(valid_options)

    new(
      importer_log_id: item.importer_log_id,
      source_id: item.source_id,
      source_type: item.source_type,
      status: "Expected #{value} to be included in #{valid_options} for #{column}",
    )
  end
end
