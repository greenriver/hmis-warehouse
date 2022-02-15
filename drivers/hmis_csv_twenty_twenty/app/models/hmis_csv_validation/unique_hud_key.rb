###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Validate that for any given importer_log_id there is only
# one record marked valid for import
class HmisCsvValidation::UniqueHudKey < HmisCsvValidation::Error
  def self.check_validity!(klass, importer_log, _options)
    incorrect_counts = klass.
      where(importer_log_id: importer_log.id).
      group(klass.hud_key).
      having(nf('COUNT', [klass.hud_key]).gt(1)).
      count
    return [] if incorrect_counts.empty?

    failures = []
    # Mark all such that they won't import
    klass.where(
      importer_log_id: importer_log.id,
      klass.hud_key => incorrect_counts.keys,
    ).
      update_all(should_import: false)
    # Mark one of each key as importable
    ids = klass.where(
      importer_log_id: importer_log.id,
      klass.hud_key => incorrect_counts.keys,
    ).
      distinct_on(klass.hud_key).
      pluck(:id)
    klass.where(id: ids).update_all(should_import: true)
    # Note those we didn't import
    klass.where(
      importer_log_id: importer_log.id,
      klass.hud_key => incorrect_counts.keys,
      should_import: false,
    ).
      find_each do |item|
        failures << new(
          importer_log_id: importer_log.id,
          source_id: item.source_id,
          source_type: item.source_type,
          status: "Non unique primary key: #{klass.hud_key}",
          validated_column: klass.hud_key,
        )
      end
    failures
  end

  def self.title
    'All primary keys must be unique'
  end
end
