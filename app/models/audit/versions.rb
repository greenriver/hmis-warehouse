###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Generic helper class for audit pages that works with any model using paper trail
class Audit::Versions
  attr_reader :record, :config

  def initialize(record, config = {})
    @record = record
    @config = default_config.merge(config)
  end

  # Versions to display on the audit page
  # Includes changes to the record itself and related entities based on configuration
  def version_array
    # Collect all version IDs from different sources, tracking their version class
    gr_paper_trail_ids = []
    grda_warehouse_ids = []

    # Start with versions for the record itself
    record_version_class = get_version_class_for_model(record.class)
    record_versions = record_version_class.where(
      item_id: record.id,
      item_type: record.class.sti_name,
    )
    if record_version_class == GrPaperTrail::Version
      gr_paper_trail_ids.concat(record_versions.pluck(:id))
    else
      grda_warehouse_ids.concat(record_versions.pluck(:id))
    end

    # Add versions for related entities
    related_versions = build_related_versions_by_class
    gr_paper_trail_ids.concat(related_versions[:gr_paper_trail])
    grda_warehouse_ids.concat(related_versions[:grda_warehouse])

    # Add versions for referenced entities (like user_group_members)
    referenced_versions = build_referenced_versions_by_class
    gr_paper_trail_ids.concat(referenced_versions[:gr_paper_trail])
    grda_warehouse_ids.concat(referenced_versions[:grda_warehouse])

    # Add versions for nested associations (like user_group_members through user_group)
    nested_versions = build_nested_versions_by_class
    gr_paper_trail_ids.concat(nested_versions[:gr_paper_trail])
    grda_warehouse_ids.concat(nested_versions[:grda_warehouse])

    # Apply exclusions
    excluded_versions = apply_exclusions_by_class
    gr_paper_trail_ids -= excluded_versions[:gr_paper_trail]
    grda_warehouse_ids -= excluded_versions[:grda_warehouse]

    gr_paper_trail_versions = GrPaperTrail::Version.where(id: gr_paper_trail_ids)
    grda_warehouse_versions = GrdaWarehouse::Version.where(id: grda_warehouse_ids)

    (gr_paper_trail_versions.to_a + grda_warehouse_versions.to_a).sort_by { |v| [v.created_at, v.id] }.reverse
  end

  def wrap_display_versions(versions)
    users_by_id = build_user_lookup(versions)
    Audit::DisplayItem.build_batch(versions, users_by_id, config[:excluded_fields])
  end

  # Class method to create multiple Audit::Versions objects with optimized loading
  def self.build_batch(records, config = {})
    return [] if records.blank?

    # Batch load all versions for all records
    batch_load_versions(records, config)

    # Create Audit::Versions objects
    records.map { |record| new(record, config) }
  end

  def self.batch_load_versions(records, config)
    return if records.blank?

    record_ids = records.map(&:id)
    record_class = records.first.class

    # Batch load versions for records themselves
    version_class = get_version_class_for_model(record_class)
    version_class.where(
      item_id: record_ids,
      item_type: record_class.sti_name,
    ).load

    # Batch load versions for related models
    batch_load_related_versions(records, config)

    # Batch load versions for referenced models
    batch_load_referenced_versions(records, config)

    # Batch load versions for nested models
    batch_load_nested_versions(records, config)
  end

  def self.batch_load_related_versions(records, config)
    return unless config[:related_models].present?

    process_related_models(records, config[:related_models]) do |model_class, related_ids|
      version_class = get_version_class_for_model(model_class)
      version_class.where(
        item_id: related_ids,
        item_type: model_class.sti_name,
      ).load
    end
  end

  def self.batch_load_referenced_versions(records, config)
    return unless config[:referenced_models].present?

    process_referenced_models(records, config[:referenced_models]) do |model_class, referenced_ids|
      version_class = get_version_class_for_model(model_class)
      version_class.where(
        item_id: referenced_ids,
        item_type: model_class.sti_name,
      ).load
    end
  end

  def self.batch_load_nested_versions(records, config)
    return unless config[:nested_models].present?

    process_nested_models(records, config[:nested_models]) do |model_class, nested_ids|
      version_class = get_version_class_for_model(model_class)
      version_class.where(
        item_id: nested_ids,
        item_type: model_class.sti_name,
      ).load
    end
  end

  def self.process_related_models(records, model_configs)
    model_configs.each do |model_config|
      model_class = model_config[:class]
      association = model_config[:association]

      related_ids = collect_related_ids(records, association)
      next if related_ids.blank?

      yield(model_class, related_ids)
    end
  end

  def self.process_referenced_models(records, model_configs)
    model_configs.each do |model_config|
      model_class = model_config[:class]
      association = model_config[:association]

      referenced_ids = collect_referenced_ids(records, association)
      next if referenced_ids.blank?

      yield(model_class, referenced_ids)
    end
  end

  def self.process_nested_models(records, model_configs)
    model_configs.each do |model_config|
      model_class = model_config[:class]
      parent_association = model_config[:parent_association]
      nested_association = model_config[:nested_association]

      nested_ids = collect_nested_ids(records, parent_association, nested_association)
      next if nested_ids.blank?

      yield(model_class, nested_ids)
    end
  end

  def self.collect_related_ids(records, association)
    records.map do |record|
      if record.respond_to?("#{association}_id")
        record.send("#{association}_id")
      else
        related_record = record.send(association)
        related_record&.id
      end
    end.compact.uniq
  end

  def self.collect_referenced_ids(records, association)
    records.flat_map do |record|
      record.send(association).with_deleted.pluck(:id) if record.respond_to?(association)
    end.compact.uniq
  end

  def self.collect_nested_ids(records, parent_association, nested_association)
    records.flat_map do |record|
      parent = record.send(parent_association) if record.respond_to?(parent_association)
      parent.send(nested_association).with_deleted.pluck(:id) if parent.respond_to?(nested_association)
    end.compact.uniq
  end

  def self.get_version_class_for_model(model_class)
    if model_class < GrdaWarehouseBase
      GrdaWarehouse::Version
    else
      GrPaperTrail::Version
    end
  end

  protected

  def default_config
    {
      # Related models to track (belongs_to relationships)
      related_models: [],

      # Referenced models to track (has_many through relationships)
      referenced_models: [],

      # Nested models to track (associations of related models)
      nested_models: [],

      # Fields to exclude from tracking (like updated_at)
      excluded_fields: [],
    }
  end

  # Determine which version class to use for a given model
  def get_version_class_for_model(model_class)
    if model_class < GrdaWarehouseBase
      GrdaWarehouse::Version
    else
      GrPaperTrail::Version
    end
  end

  # Generic method to collect version IDs by class
  def collect_version_ids_by_class(model_class, record_ids)
    return { gr_paper_trail: [], grda_warehouse: [] } if record_ids.blank?

    version_class = get_version_class_for_model(model_class)
    version_ids = version_class.where(
      item_type: model_class.sti_name,
      item_id: record_ids,
    ).pluck(:id)

    if version_class == GrPaperTrail::Version
      { gr_paper_trail: version_ids, grda_warehouse: [] }
    else
      { gr_paper_trail: [], grda_warehouse: version_ids }
    end
  end

  def build_related_versions_by_class
    return { gr_paper_trail: [], grda_warehouse: [] } if config[:related_models].blank?

    gr_paper_trail_ids = []
    grda_warehouse_ids = []

    self.class.process_related_models([record], config[:related_models]) do |model_class, related_ids|
      version_ids = collect_version_ids_by_class(model_class, related_ids)
      gr_paper_trail_ids.concat(version_ids[:gr_paper_trail])
      grda_warehouse_ids.concat(version_ids[:grda_warehouse])
    end

    { gr_paper_trail: gr_paper_trail_ids, grda_warehouse: grda_warehouse_ids }
  end

  def build_referenced_versions_by_class
    return { gr_paper_trail: [], grda_warehouse: [] } if config[:referenced_models].blank?

    gr_paper_trail_ids = []
    grda_warehouse_ids = []

    self.class.process_referenced_models([record], config[:referenced_models]) do |model_class, referenced_ids|
      version_ids = collect_version_ids_by_class(model_class, referenced_ids)
      gr_paper_trail_ids.concat(version_ids[:gr_paper_trail])
      grda_warehouse_ids.concat(version_ids[:grda_warehouse])
    end

    { gr_paper_trail: gr_paper_trail_ids, grda_warehouse: grda_warehouse_ids }
  end

  def build_nested_versions_by_class
    return { gr_paper_trail: [], grda_warehouse: [] } if config[:nested_models].blank?

    gr_paper_trail_ids = []
    grda_warehouse_ids = []

    self.class.process_nested_models([record], config[:nested_models]) do |model_class, nested_ids|
      version_ids = collect_version_ids_by_class(model_class, nested_ids)
      gr_paper_trail_ids.concat(version_ids[:gr_paper_trail])
      grda_warehouse_ids.concat(version_ids[:grda_warehouse])
    end

    { gr_paper_trail: gr_paper_trail_ids, grda_warehouse: grda_warehouse_ids }
  end

  def apply_exclusions_by_class
    return { gr_paper_trail: [], grda_warehouse: [] } if config[:excluded_fields].blank?

    # Get IDs of versions that only contain excluded fields
    record_version_class = get_version_class_for_model(record.class)
    excluded_ids = record_version_class.where(
      item_id: record.id,
      item_type: record.class.sti_name,
    ).matching_object_change_fields(*config[:excluded_fields]).pluck(:id)

    if record_version_class == GrPaperTrail::Version
      { gr_paper_trail: excluded_ids, grda_warehouse: [] }
    else
      { gr_paper_trail: [], grda_warehouse: excluded_ids }
    end
  end

  # lookup table for the users that created these versions, avoids n+1
  def build_user_lookup(versions)
    user_ids = versions.flat_map do |version|
      [version.clean_user_id, version.clean_true_user_id] unless version.anonymous?
    end

    user_ids = user_ids.compact.map(&:to_i).uniq
    User.with_deleted.where(id: user_ids).index_by(&:id)
  end
end
