###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HMIS uses similar but separate permissions system from the warehouse
# See drivers/hmis/doc/PERMISSIONS.md

module Hmis
  class GroupViewableEntity < GrdaWarehouseBase
    acts_as_paranoid
    has_paper_trail

    # TODO: rename AccessGroup class to `Collection`, update all references
    belongs_to :collection, class_name: 'Hmis::AccessGroup', inverse_of: :group_viewable_entities
    alias access_group collection

    belongs_to :entity, polymorphic: true

    has_many :group_viewable_entity_projects
    has_many :projects, through: :group_viewable_entity_projects, source: :project

    scope :projects, -> { where(entity_type: Hmis::Hud::Project.sti_name) }
    scope :organizations, -> { where(entity_type: Hmis::Hud::Organization.sti_name) }
    scope :data_sources, -> { where(entity_type: GrdaWarehouse::DataSource.sti_name) }

    scope :includes_project, ->(project) do
      joins(:projects).where(p_t[:id].eq(project.id))
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
      when ::GrdaWarehouse::DataSource.name
        includes_data_source(entity)
      else
        none
      end
    end

    scope :includes_entities, ->(entities) do
      where(id: Array(entities).flat_map { |entity| includes_entity(entity).pluck(:id) })
    end
  end
end
