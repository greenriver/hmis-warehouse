###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Specifies which polymorphic entity (and/or service type) that a given form is applicable to.
class Hmis::Form::Instance < ::GrdaWarehouseBase
  include Hmis::Concerns::HmisArelHelper
  self.table_name = :hmis_form_instances

  belongs_to :entity, polymorphic: true, optional: true
  belongs_to :definition, foreign_key: :definition_identifier, primary_key: :identifier, class_name: 'Hmis::Form::Definition'

  belongs_to :custom_service_category, optional: true, class_name: 'Hmis::Hud::CustomServiceCategory'
  belongs_to :custom_service_type, optional: true, class_name: 'Hmis::Hud::CustomServiceType'

  scope :for_projects, -> { where(entity_type: Hmis::Hud::Project.sti_name) }
  scope :for_organizations, -> { where(entity_type: Hmis::Hud::Organization.sti_name) }
  scope :defaults, -> { where(entity_type: nil, entity_id: nil, project_type: nil, funder: nil) }

  # Find instances that are for a specific Project
  scope :for_project, ->(project_id) { for_projects.where(entity_id: project_id) }

  # Find instances that are for a specific Organization
  scope :for_organization, ->(organization_id) { for_organizations.where(entity_id: organization_id) }

  # Find instances that match a project based on Project Type and Funder
  scope :for_project_by_type_or_funder, ->(project) do
    funders = project.funders.pluck(:funder).compact
    matches_funder = fi_t[:funder].in(funders).or(fi_t[:funder].eq(nil))
    matches_type = fi_t[:project_type].eq(project.project_type).or(fi_t[:project_type].eq(nil))

    funder_or_project_type_exists = fi_t[:funder].not_eq(nil).or(fi_t[:project_type].not_eq(nil))
    where(funder_or_project_type_exists.and(matches_type.or(matches_funder)))
  end

  # Find instances that are for a Service Type
  scope :for_service_type, ->(service_type_id) { where(custom_service_type_id: service_type_id) }
  # Find instances that are for a Service Category
  scope :for_service_category, ->(category_id) { where(custom_service_category_id: category_id) }

  # Find instances that are specified by service type or service category
  scope :for_services, -> do
    where(fi_t[:custom_service_type_id].not_eq(nil).or(fi_t[:custom_service_category_id].not_eq(nil)))
  end

  scope :for_project_through_entities, ->(project) do
    ids = Hmis::Form::Instance.for_project(project.id).pluck(:id)
    ids += Hmis::Form::Instance.for_organization(project.organization.id).pluck(:id)
    ids += Hmis::Form::Instance.for_project_by_type_or_funder(project).pluck(:id)
    ids += defaults.pluck(:id)
    where(id: ids)
  end
end
