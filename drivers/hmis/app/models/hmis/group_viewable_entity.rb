###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class GroupViewableEntity < GrdaWarehouse::GroupViewableEntity
    acts_as_paranoid

    belongs_to :access_group, class_name: '::Hmis::AccessGroup', inverse_of: :group_viewable_entities
    belongs_to :entity, polymorphic: true

    scope :projects, -> { where(entity_type: Hmis::Hud::Project.sti_name) }
    scope :organizations, -> { where(entity_type: Hmis::Hud::Organization.sti_name) }
    scope :data_sources, -> { where(entity_type: GrdaWarehouse::DataSource.sti_name) }
    scope :project_access_groups, -> { where(entity_type: GrdaWarehouse::ProjectAccessGroup.sti_name) }

    scope :includes_project, ->(project) do
      where(entity_type: project.class.sti_name, entity_id: project.id).
        or(includes_data_source(project.data_source)).
        or(includes_organization(project.organization)).
        or(includes_project_access_groups(project.project_groups))
    end

    scope :includes_project_access_group, ->(pag) do
      where(entity: pag)
    end

    scope :includes_project_access_groups, ->(pags) do
      where(entity_type: GrdaWarehouse::ProjectAccessGroup.name, entity_id: pags.pluck(:id))
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
      when Hmis::Hud::Organization.name
        includes_organization(entity)
      when GrdaWarehouse::DataSource.name
        includes_data_source(entity)
      when GrdaWarehouse::ProjectAccessGroup.name
        includes_project_access_group(entity)
      else
        none
      end
    end

    scope :includes_entities, ->(entities) do
      where(id: Array(entities).flat_map { |entity| includes_entity(entity).pluck(:id) })
    end
  end
end
