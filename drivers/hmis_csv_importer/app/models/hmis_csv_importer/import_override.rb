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
    order(:file_name, :replaces_column, :matched_hud_key)
  end

  def self.file_name_keys
    available_classes.map do |file_name, data|
      model = data[:model]
      [file_name, { key: model.hud_key, columns: model.hmis_configuration(version: '2024').keys.map(&:to_s).sort - [model.hud_key] }]
    end.to_h
  end

  def self.available_classes
    Importers::HmisAutoMigrate.available_migrations.values.last.constantize::TRANSFORM_TYPES
  end

  def self.available_files
    available_classes.keys
  end

  def self.available_files_for(data_source_id)
    where(data_source_id: data_source_id).distinct.pluck(:file_name).sort
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

  # Accepts an object or hash representing the item that might be overridden
  # and an optional set of overrides to check.
  # If you are checking many rows at a time, you may want to pass in the overrides
  # so that you can calculate them only once.
  def self.any_apply?(row, overrides = nil)
    overrides ||= HmisCsvImporter::ImportOverride.
      where(data_source: row.data_source).
      sorted

    applied_overrides = overrides.to_a.select { |override| override.applies?(row) }
    applied_overrides.any?
  end

  # Accepts either an object based on GrdaWarehouse::Hud::Base, or a has of attributes with string keys
  # Returns same object with overides applied
  # NOTE: this does not save the object
  def apply(row)
    return row unless applies?(row)

    # We either have the right HUD Key, or the right source value, or both
    # or we weren't looking for anything specific
    # Just replace the data
    row[replaces_column] = replacement_value == ':NULL:' ? nil : replacement_value

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

  def describe_apply
    # build a more human readable description of the override when applied.
    with_clause = describe_with
    with_clause = 'removed' if with_clause.nil?
    with_clause = 'replaced with ' + with_clause unless describe_with.nil?

    when_clause = 'where ' + describe_when
    when_clause = 'for all associated records' if describe_when == 'always'

    "#{replaces_column} has been #{with_clause} #{when_clause}."
  end

  def describe_with
    replacement_value == ':NULL:' ? nil : replacement_value
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

  def project
    # Only return projects for PDDE classes
    return [] unless associated_class.column_names.include?('ProjectID')
    return [] if associated_class.column_names.include?('EnrollmentID')
    return [] if matched_hud_key.blank? && replaces_value.blank?

    project_ids = associated_class.where(data_source_id: data_source_id).to_a.select do |row|
      applies?(row)
    end.map(&:ProjectID)
    # Limit to 10 for performance
    GrdaWarehouse::Hud::Project.where(data_source_id: data_source_id, ProjectID: project_ids.uniq.first(10)).to_a
  end

  def apply_to_warehouse
    scope = associated_class.where(data_source_id: data_source_id)
    scope = scope.where(associated_class.hud_key => matched_hud_key) if matched_hud_key.present?
    scope = scope.where(replaces_column => replaces_value) if replaces_value.present?
    scope.update_all(replaces_column => replacement_value)
  end
end
