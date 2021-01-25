###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvValidation::OneHeadOfHousehold < HmisCsvValidation::Validation
  def self.check_validity!(klass, importer_log, _options)
    incorrect_household_ids = klass.
      where(importer_log_id: importer_log.id, RelationshipToHoH: 1).
      group(:HouseholdID).
      having(nf('COUNT', [:HouseholdID]).gt(1)).
      count
    return [] if incorrect_household_ids.empty?

    failures = []
    klass.where(
      importer_log_id: importer_log.id,
      HouseholdID: incorrect_household_ids.keys,
    ).find_each do |item|
      failures << new(
        importer_log_id: importer_log.id,
        source_id: item.source_id,
        source_type: item.source_type,
        status: 'More than one Head of Household',
        validated_column: column,
      )
    end
    failures
  end

  def self.title
    'Households must have exactly one head of household'
  end
end
