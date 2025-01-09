###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UniqueName < ApplicationRecord
  # Build double metaphone representations for all names in the database
  def self.update!(...)
    with_advisory_lock('UniqueNameUpdate', timeout_seconds: 0) { _update!(...) }
  end

  def self._update!(batch_size: 5_000)
    Rails.logger.info 'Updating the unique names table'

    existing_names = {}
    UniqueName.all.pluck_in_batches(:name, batch_size: batch_size) do |batch|
      batch.each { |name| existing_names[name] = false }
    end

    name_cols = [:first_name, :last_name]
    GrdaWarehouse::Hud::Client.source.pluck_in_batches(name_cols, batch_size: batch_size) do |batch|
      inserts = []
      batch.each do |row|
        row.each do |name|
          next if name.blank?

          name = name.strip.downcase
          next if name.length > 100

          name_exists = name.in?(existing_names)
          existing_names[name] = true
          next if name_exists

          double_metaphone = Text::Metaphone.double_metaphone(name)
          inserts << UniqueName.new(name: name, double_metaphone: double_metaphone)
        end
      end
      next if inserts.empty?

      result = UniqueName.import(inserts)
      raise "Failed to import UniqueName: #{result.inspect}" if result.failed_instances.present?
    end

    # remove names that are no longer used
    missing_names = []
    existing_names.filter do |name, exists|
      missing_names << name unless exists
    end
    missing_names.each_slice(batch_size) do |batch|
      UniqueName.where(name: batch).delete_all
    end
  end
end
