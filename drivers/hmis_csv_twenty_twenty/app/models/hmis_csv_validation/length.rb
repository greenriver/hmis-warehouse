###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvValidation::Length < HmisCsvValidation::Error
  def self.check_validity!(item, column, min: 0, max:)
    value = item[column].to_s
    return if value.size >= min && value.size <= max

    new(
      importer_log_id: item.importer_log_id,
      source_id: item.source_id,
      source_type: item.source_type,
      status: "The length of #{column} must be in range #{min}..#{max}",
    )
  end
end
