###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Generic wrapper around a paper trail version to assist with display logic
class Audit::DisplayItem
  attr_reader :version, :username, :impersonating, :error, :changes, :entity_name, :entity_display_name
  delegate :created_at, :event, :item_type, :item_id, to: :version

  def initialize(version, users_by_id, excluded_fields = [], records_by_type_and_id = {})
    raise ArgumentError, "Expected GrPaperTrail::Version or GrdaWarehouse::Version, got #{version.class}" unless version.is_a?(GrPaperTrail::Version) || version.is_a?(GrdaWarehouse::Version)

    @version = version
    @excluded_fields = excluded_fields
    @records_by_type_and_id = records_by_type_and_id

    impersonating = version.clean_true_user_id.present? && version.clean_user_id.to_s != version.clean_true_user_id.to_s

    true_username = compute_username(users_by_id, version.clean_true_user_id)
    username = compute_username(users_by_id, version.clean_user_id)
    @username = true_username || username || version.whodunnit.presence
    @impersonating = username if true_username && impersonating

    begin
      klass = version.item_type.constantize
      @entity_name = compute_entity_name(klass)
      @entity_display_name = compute_entity_display_name(klass)
    rescue NameError
      @error = true
      @entity_name = version.item_type
      @entity_display_name = version.item_type
    end

    begin
      changeset = version.changes_with_computed_fallback unless @error
    rescue StandardError
      @error = true
    end

    @changes = if @error
      ['Error loading changes']
    elsif klass.respond_to?(:describe_changes)
      klass.describe_changes(version, changeset, @excluded_fields)
    else
      # Fallback for models without describe_changes method
      describe_changes_fallback(version, changeset)
    end
  end

  # Class method to create multiple display items with optimized loading
  def self.build_batch(versions, users_by_id, excluded_fields = [])
    return [] if versions.blank?

    # Pre-load all records referenced in versions
    records_by_type_and_id = preload_records_for_versions(versions)

    # Create display items with pre-loaded records
    versions.map do |version|
      new(version, users_by_id, excluded_fields, records_by_type_and_id)
    end
  end

  # Class method to pre-load records for a collection of versions
  def self.preload_records_for_versions(versions)
    return {} if versions.blank?

    records_by_type_and_id = {}

    # Group versions by item_type
    versions_by_type = versions.group_by(&:item_type)

    versions_by_type.each do |item_type, type_versions|
      klass = item_type.constantize
      item_ids = type_versions.map(&:item_id).uniq

      # Load records with deleted ones included
      records = if klass.respond_to?(:with_deleted)
        klass.with_deleted.where(id: item_ids).index_by(&:id)
      else
        klass.where(id: item_ids).index_by(&:id)
      end

      records_by_type_and_id[item_type] = records
    end

    records_by_type_and_id
  end

  protected

  def compute_username(users_by_id, user_id)
    return if version.anonymous?
    return unless user_id

    user = users_by_id[user_id.to_i]
    user&.name.presence || "User ID #{user_id}"
  end

  def compute_entity_name(klass)
    # Special handling for GroupViewableEntity - show the referenced entity type
    return GrdaWarehouse::GroupViewableEntity.item_type(version) if klass == GrdaWarehouse::GroupViewableEntity

    klass.name
  end

  def compute_entity_display_name(klass)
    record = @records_by_type_and_id&.dig(version.item_type, version.item_id)
    record ||= klass.with_deleted.find_by(id: version.item_id)

    display_name = record&.entity_name
    display_name ||= record&.name

    display_name || version.item_type.underscore.humanize
  end

  def describe_changes_fallback(version, changeset)
    entity_display_name = compute_entity_display_name(nil)

    case version.event
    when 'create'
      ["Created #{entity_display_name}"]
    when 'update'
      if changeset.present?
        changeset.map do |field, values|
          from, to = values
          "Changed #{field.humanize.titleize}: from #{render_changed_value(field, from)} to #{render_changed_value(field, to)}"
        end
      else
        ["Modified #{entity_display_name}"]
      end
    when 'destroy'
      ["Deleted #{entity_display_name}"]
    else
      ["Modified #{entity_display_name}"]
    end
  end

  def render_changed_value(_field, value)
    return 'nil' if value.nil?

    return value.to_s
  end
end
