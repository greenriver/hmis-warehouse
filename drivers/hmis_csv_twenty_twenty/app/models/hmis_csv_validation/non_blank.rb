###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvValidation::NonBlank < HmisCsvValidation::Error
  def self.check_validity!(item, column, _args)
    value = item[column]
    return if value.present?

    new(
      importer_log_id: item.importer_log_id,
      source_id: item.source_id,
      source_type: item.source_type,
      status: "A value is required for #{column}",
    )
  end
end
