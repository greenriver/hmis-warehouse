###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvValidation::InclusionInSet < HmisCsvValidation::Validation
  def self.check_validity!(item, column, valid_options: nil)
    value = item[column]
    return true if value.blank? || value.in?(valid_options)

    create(
      importer_log_id: item.importer_log_id,
      source: item,
      status: "Expected #{value} to be included in #{valid_options}",
    )
  end
end
