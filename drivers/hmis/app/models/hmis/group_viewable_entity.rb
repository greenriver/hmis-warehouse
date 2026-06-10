###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# HMIS uses similar but separate permissions system from the warehouse
# See drivers/hmis/doc/PERMISSIONS.md

module Hmis
  class GroupViewableEntity < GrdaWarehouseBase
    acts_as_paranoid
    has_paper_trail

    # TODO: rename AccessGroup class to `Collection`, update all references
    belongs_to :collection, class_name: 'Hmis::AccessGroup', inverse_of: :group_viewable_entities

    belongs_to :entity, polymorphic: true

    has_many :group_viewable_entity_projects
    has_many :projects, through: :group_viewable_entity_projects, source: :project

    scope :projects, -> { where(entity_type: Hmis::Hud::Project.sti_name) }
    scope :project_groups, -> { where(entity_type: Hmis::ProjectGroup.sti_name) }
    scope :organizations, -> { where(entity_type: Hmis::Hud::Organization.sti_name) }
    scope :data_sources, -> { where(entity_type: ::GrdaWarehouse::DataSource.sti_name) }

    scope :includes_project, ->(project) do
      joins(:projects).where(p_t[:id].eq(project.id))
    end

    scope :includes_project_group, ->(project_group) do
      where(entity: project_group)
    end

    scope :includes_organization, ->(organization) do
      where(entity: organization).or(includes_data_source(organization.data_source))
    end

    scope :includes_data_source, ->(data_source) do
      where(entity: data_source)
    end

    scope :includes_entity, ->(entity) do
      case entity.class.name
      when Hmis::Hud::Project.name
        includes_project(entity)
      when Hmis::ProjectGroup.name
        includes_project_group(entity)
      when Hmis::Hud::Organization.name
        includes_organization(entity)
      when ::GrdaWarehouse::DataSource.name
        includes_data_source(entity)
      else
        none
      end
    end

    scope :includes_entities, ->(entities) do
      where(id: Array(entities).flat_map { |entity| includes_entity(entity).pluck(:id) })
    end

    scope :includes_any_entity_in_data_source, ->(data_source) do
      project_ids = data_source.projects.select(:id)
      organization_ids = data_source.organizations.select(:id)
      project_group_ids = data_source.hmis_project_groups.select(:id)

      where(entity: data_source).
        or(where(entity_type: Hmis::Hud::Project.sti_name, entity_id: project_ids)).
        or(where(entity_type: Hmis::Hud::Organization.sti_name, entity_id: organization_ids)).
        or(where(entity_type: Hmis::ProjectGroup.sti_name, entity_id: project_group_ids))
    end

    def access_group
      collection
    end

    def entity_name
      group_name = collection&.name || 'Unknown Collection'
      entity_display = case entity_type
      when 'Hmis::Hud::Project'
        "Project: #{entity&.ProjectName || entity_id}"
      when 'Hmis::Hud::Organization'
        "Organization: #{entity&.OrganizationName || entity_id}"
      when 'GrdaWarehouse::DataSource'
        "Data Source: #{entity&.name || entity_id}"
      when 'Hmis::ProjectGroup'
        "Project Group: #{entity&.name || entity_id}"
      else
        entity&.name || "Entity: #{entity_id}"
      end

      "Collection: #{group_name} - #{entity_display}"
    end

    def self.describe_changes(version, _changes, _excluded_fields = [])
      index = version.event == 'destroy' ? 0 : 1

      entity_name = if version.item
        version.item.entity_name
      else
        object_changes = version.object_changes
        entity_id = object_changes&.dig('entity_id', index)
        entity_type = object_changes&.dig('entity_type', index)
        collection_id = object_changes&.dig('collection_id', index)
        collection = Hmis::AccessGroup.with_deleted.find_by(id: collection_id)
        "#{entity_type&.demodulize || 'Entity'} #{entity_id} in #{collection&.name || "Collection #{collection_id}"}"
      end

      case version.event
      when 'create'
        ["Added #{entity_name}"]
      when 'destroy'
        ["Removed #{entity_name}"]
      else
        ["Updated #{entity_name}"]
      end
    end
  end
end
