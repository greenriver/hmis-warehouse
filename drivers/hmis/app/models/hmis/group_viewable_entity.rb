###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  class GroupViewableEntity < GrdaWarehouse::GroupViewableEntity
    acts_as_paranoid

    belongs_to :access_group, class_name: '::Hmis::AccessGroup'
    belongs_to :entity, polymorphic: true

    scope :includes_project, ->(project) do
      pags = project.project_groups
      where(entity_type: project.class.name, entity_id: project.id).
        or(includes_data_source(project.data_source)).
        or(includes_organization(project.organization)).
        or(includes_data_source(project.organization.data_source)).
        or(where(entity_type: GrdaWarehouse::ProjectAccessGroup.name, entity_id: pags.pluck(:id)))
    end

    scope :includes_project_access_group, ->(pag) do
      where(entity_type: GrdaWarehouse::ProjectAccessGroup.name, entity_id: pag.id)
    end

    scope :includes_organization, ->(organization) do
      where(entity_type: organization.class.name, entity_id: organization.id).
        or(includes_data_source(organization.data_source))
    end

    scope :includes_data_source, ->(data_source) do
      where(entity_type: data_source.class.name, entity_id: data_source.id)
    end
  end
end
