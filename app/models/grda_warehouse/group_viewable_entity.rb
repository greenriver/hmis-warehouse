###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Participates in both the "new" and "legacy" permissions system
# * A GroupViewableEntity maps an "entity" (project, organization, etc) to a Collection (new) or an AccessGroup (legacy)
# * should have either an access_group_id or a collection_id but not both
module GrdaWarehouse
  class GroupViewableEntity < GrdaWarehouseBase
    acts_as_paranoid
    has_paper_trail

    # records with a access_group_id are part of the "legacy" permission system
    belongs_to :access_group, optional: true
    # records with a collection_id are part of the "new" permission system
    belongs_to :entity, polymorphic: true
    belongs_to :collection, optional: true

    scope :viewable_by, ->(user) do
      where(access_group_id: user.access_groups.pluck(:id))
    end

    def self.item_type(item)
      record = with_deleted.find_by(id: item.item_id)
      if record&.entity_type
        record.entity_type
      else
        item.item_type
      end
    end

    def entity_name
      collection_name = collection&.name || 'Unknown Collection'
      entity_display_name = case entity_type
      when 'GrdaWarehouse::Lookups::CocCode'
        "CoC Code: #{entity&.coc_code || entity_id}"
      when 'GrdaWarehouse::Hud::Project'
        "Project: #{entity&.ProjectName || entity_id}"
      when 'GrdaWarehouse::Hud::Organization'
        "Organization: #{entity&.OrganizationName || entity_id}"
      when 'GrdaWarehouse::DataSource'
        "Data Source: #{entity&.name || entity_id}"
      when 'GrdaWarehouse::ProjectAccessGroup'
        "Project Group for Project Access: #{entity&.name || entity_id}"
      when 'GrdaWarehouse::WarehouseReports::ReportDefinition'
        "Report: #{entity&.name || entity_id}"
      when 'GrdaWarehouse::Cohort'
        "Cohort: #{entity&.name || entity_id}"
      when 'GrdaWarehouse::ProjectGroup'
        "Project Group: #{entity&.name || entity_id}"
      else
        entity&.name || "Entity: #{entity_id}"
      end

      "Collection: #{collection_name} - #{entity_display_name}"
    end

    def self.describe_changes(version, _changes, _excluded_fields = [])
      # PaperTrail stores changes in object_changes as: { field_name => [old_value, new_value] }
      # Examples:
      # - Create: { 'entity_id' => [nil, 123], 'entity_type' => [nil, 'GrdaWarehouse::Hud::Project'] }
      # - Update: { 'entity_id' => [123, 456], 'entity_type' => ['GrdaWarehouse::Hud::Project', 'GrdaWarehouse::Hud::Organization'] }
      # - Destroy: { 'entity_id' => [123, nil], 'entity_type' => ['GrdaWarehouse::Hud::Project', nil] }
      #
      # For create events: use index 1 (new value)
      # For destroy events: use index 0 (old value)
      # For update events: use index 1 (new value)
      index = version.event == 'destroy' ? 0 : 1

      # Guard against YAML deserialization failures on old records (see Version#safe_object).
      obj = version.safe_object
      obj_changes = version.safe_object_changes

      # Get the entity name from the version's item or version data
      entity_name = if version.item
        get_entity_display_name(version.item.entity_type, version.item.entity_id, version.item.entity)
      elsif ['create', 'destroy', 'update'].include?(version.event)
        if obj.present?
          get_entity_display_name(obj['entity_type'], obj['entity_id'])
        elsif obj_changes.present?
          entity_id = obj_changes['entity_id']&.[](index)
          entity_type = obj_changes['entity_type']&.[](index)
          get_entity_display_name(entity_type, entity_id)
        end
      end
      entity_name ||= 'Unknown Entity'

      # Get the collection/access_group name (GVEs use collection_id for ACL or access_group_id for legacy)
      changes = obj_changes || {}
      path_name = if version.item
        if version.item.collection_id.present?
          version.item.collection&.name || "Collection ID #{version.item.collection_id}"
        elsif version.item.access_group_id.present?
          version.item.access_group&.name || "Access Group ID #{version.item.access_group_id}"
        else
          'Unknown Collection or Group'
        end
      elsif ['create', 'destroy'].include?(version.event)
        if changes['collection_id']
          collection_id = changes['collection_id'][index]
          collection = Collection.with_deleted.find_by(id: collection_id)
          collection&.name || "Collection ID #{collection_id}"
        elsif changes['access_group_id']
          access_group_id = changes['access_group_id'][index]
          access_group = AccessGroup.with_deleted.find_by(id: access_group_id)
          access_group&.name || "Access Group ID #{access_group_id}"
        elsif obj&.dig('collection_id').present?
          # Fall back to object column if object_changes has no path data. A GVE's object snapshot
          # always carries both columns with one nil, so key off the populated value, not the key.
          collection = Collection.with_deleted.find_by(id: obj['collection_id'])
          collection&.name || "Collection ID #{obj['collection_id']}"
        elsif obj&.dig('access_group_id').present?
          access_group = AccessGroup.with_deleted.find_by(id: obj['access_group_id'])
          access_group&.name || "Access Group ID #{obj['access_group_id']}"
        else
          'Unknown Collection or Group'
        end
      else
        'Unknown Collection or Group'
      end

      case version.event
      when 'create'
        ["Added \"#{entity_name}\" to \"#{path_name}\""]
      when 'update'
        ["Modified \"#{entity_name}\" in \"#{path_name}\""]
      when 'destroy'
        ["Removed \"#{entity_name}\" from \"#{path_name}\""]
      else
        ['Modified collection entity']
      end
    end

    def self.get_entity_display_name(entity_type, entity_id, entity = nil)
      return "Entity ID #{entity_id}" unless entity_type && entity_id

      entity ||= begin
        klass = entity_type.constantize
        if klass.respond_to?(:with_deleted)
          klass.with_deleted.find_by(id: entity_id)
        else
          klass.find_by(id: entity_id)
        end
      rescue NameError => e
        # The stored entity_type references a class that no longer exists; degrade to the id
        # rather than raising out of the audit render.
        Rails.logger.warn("GroupViewableEntity.get_entity_display_name: unknown entity_type #{entity_type.inspect}: #{e.message}")
        return "Entity ID #{entity_id}"
      end
      entity&.name
    end
  end
end
