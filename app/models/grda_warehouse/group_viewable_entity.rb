###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
        "Project Group: #{entity&.name || entity_id}"
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
      # Get the entity name from the version's item or object_changes
      entity_name = if version.item
        get_entity_display_name(version.item.entity_type, version.item.entity_id, version.item.entity)
      elsif version.object_changes&.dig('entity_id', 1)
        # For create events, get the entity name from the new entity_id
        entity_id = version.object_changes['entity_id'][1]
        entity_type = version.object_changes['entity_type']&.last || version.object_changes['entity_type']&.first
        get_entity_display_name(entity_type, entity_id)
      elsif version.object_changes&.dig('entity_id', 0)
        # For destroy events, get the entity name from the original entity_id
        entity_id = version.object_changes['entity_id'][0]
        entity_type = version.object_changes['entity_type']&.first
        get_entity_display_name(entity_type, entity_id)
      else
        'Unknown Entity'
      end

      # Get the collection name
      collection_name = if version.item
        version.item.collection&.name || "Collection ID #{version.item.collection_id}"
      elsif version.object_changes&.dig('collection_id', 1)
        collection_id = version.object_changes['collection_id'][1]
        collection = Collection.with_deleted.find_by(id: collection_id)
        collection&.name || "Collection ID #{collection_id}"
      elsif version.object_changes&.dig('collection_id', 0)
        # For destroy events, get the collection name from the original collection_id
        collection_id = version.object_changes['collection_id'][0]
        collection = Collection.with_deleted.find_by(id: collection_id)
        collection&.name || "Collection ID #{collection_id}"
      else
        'Unknown Collection'
      end

      case version.event
      when 'create'
        ["Added \"#{entity_name}\" to \"#{collection_name}\""]
      when 'update'
        ["Modified \"#{entity_name}\" in \"#{collection_name}\""]
      when 'destroy'
        ["Removed \"#{entity_name}\" from \"#{collection_name}\""]
      else
        ['Modified collection entity']
      end
    end

    def self.get_entity_display_name(entity_type, entity_id, entity = nil)
      return "Entity ID #{entity_id}" unless entity_type && entity_id

      entity ||= entity_type.constantize.with_deleted.find_by(id: entity_id)
      entity&.name
    end
  end
end
