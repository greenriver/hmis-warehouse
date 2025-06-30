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

  def initialize(version, users_by_id, excluded_fields = [])
    raise ArgumentError, "Expected GrPaperTrail::Version or GrdaWarehouse::Version, got #{version.class}" unless version.is_a?(GrPaperTrail::Version) || version.is_a?(GrdaWarehouse::Version)

    @version = version
    @excluded_fields = excluded_fields

    true_username = compute_username(users_by_id, version.clean_true_user_id)
    username = compute_username(users_by_id, version.clean_user_id)
    @username = true_username || username || version.whodunnit.presence
    @impersonating = username if true_username && username != true_username

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

  protected

  def compute_username(users_by_id, user_id)
    return if version.anonymous?
    return unless user_id

    user = users_by_id[user_id.to_i]
    user&.name.presence || "User ID #{user_id}"
  end

  def compute_entity_name(klass)
    # Special handling for GroupViewableEntity - show the referenced entity type
    if klass == GrdaWarehouse::GroupViewableEntity
      begin
        record = klass.with_deleted.find_by(id: version.item_id)
        if record&.entity_type
          record.entity_type
        else
          version.item_type
        end
      rescue StandardError
        version.item_type
      end
    else
      klass.name
    end
  end

  def compute_entity_display_name(klass)
    # Try to get the actual record and use its name method first
    if klass
      begin
        record = klass.with_deleted.find_by(id: version.item_id)
        if record.respond_to?(:entity_name)
          return record.entity_name
        elsif record.respond_to?(:name)
          return record.name
        end
      rescue StandardError
        # If we can't load the record, fall back to humanized entity type
      end
    end

    # Fallback to humanized entity type
    version.item_type.underscore.humanize
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
    return 'true' if value == true
    return 'false' if value == false
    return value.to_s if value.is_a?(Numeric)
    return value.to_s if value.is_a?(String)

    return value.to_s
  end
end
