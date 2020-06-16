###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvValidation::NonBlank < HmisCsvValidation::Error
  def self.check_validity!(item, column, _args)
    value = item[column]
    return true if value.present?

    create(
      importer_log_id: item.importer_log_id,
      source: item,
      status: "A value is required for #{column}",
    )
  end
end
