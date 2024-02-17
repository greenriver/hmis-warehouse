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

  def describe_with
    "replaces #{replaces_column} with #{replacement_value}"
  end

  def describe_when
    return 'always' if matched_hud_key.blank? && replaces_value.blank?
    return "when #{associated_class.hud_key} is #{matched_hud_key} and #{replaces_column} is #{replaces_value}" if matched_hud_key.present? && replaces_value.present?
    return "when #{associated_class.hud_key} is #{matched_hud_key}" if matched_hud_key.present?

    "when #{replaces_column} is #{replaces_value}" if replaces_value.present?
  end

  def associated_class
    self.class.available_classes.dig(file_name, :model)
  end
end
