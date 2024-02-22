###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::ImportOverride < GrdaWarehouseBase
  belongs_to :data_source
  has_paper_trail
  acts_as_paranoid
  belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  scope :sorted, -> do
    order(:file_name, :matched_hud_key)
  end

  def self.available_classes
    Importers::HmisAutoMigrate.available_migrations.values.last.constantize::TRANSFORM_TYPES
  end

  def self.available_files
    available_classes.keys
  end

  def self.known_columns
    [
      :file_name,
      :matched_hud_key,
      :replaces_column,
      :replaces_value,
      :replacement_value,
    ]
  end

  # Accepts either an object based on GrdaWarehouse::Hud::Base, or a has of attributes with string keys
  # Returns same object with overides applied
  # NOTE: this does not save the object
  def apply(row)
    return row unless applies?(row)

    # We either have the right HUD Key, or the right source value, or both
    # or we weren't looking for anything specific
    # Just replace the data
    row[replaces_column] = replacement_value

    row
  end

  private def normalize_row(row)
    return row.attributes if row.is_a?(GrdaWarehouse::Hud::Base)

    row
  end

  def applies?(row)
    row = normalize_row(row)
    # Double check we actually have the column we're looking for (protects against typos or future spec changes)
    return false unless row.key?(replaces_column)
    # We were expecting a specific HUD key, and this is not it
    return false if matched_hud_key.presence&.!= row[hud_key]
    # We were expecting a specific value, and this is not it
    return false if replaces_value.presence&.!= row[replaces_column]

    true
  end

  # Least specific should be run first
  def specificity
    if matched_hud_key && replaces_value
      3
    elsif replaces_value
      2
    elsif matched_hud_key
      1
    else
      0
    end
  end

  def describe_with
    replacement_value
  end

  def describe_when
    return 'always' if matched_hud_key.blank? && replaces_value.blank?
    return "#{associated_class.hud_key} is #{matched_hud_key} and #{replaces_column} is #{replaces_value}" if matched_hud_key.present? && replaces_value.present?
    return "#{associated_class.hud_key} is #{matched_hud_key}" if matched_hud_key.present?

    "#{replaces_column} is #{replaces_value}" if replaces_value.present?
  end

  def associated_class
    self.class.available_classes.dig(file_name, :model)
  end

  def hud_key
    associated_class.hud_key.to_s
  end
end
