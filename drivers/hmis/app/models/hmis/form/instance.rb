###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::Instance < ::GrdaWarehouseBase
  include Hmis::Concerns::HmisArelHelper
  self.table_name = :hmis_form_instances

  # ! If entity is ProjectType, then using this association directly might cause issues since the ID points to an enum value, not an actual AR entity
  belongs_to :entity, polymorphic: true, optional: true
  belongs_to :definition, foreign_key: :definition_identifier, primary_key: :identifier, class_name: 'Hmis::Form::Definition'

  belongs_to :custom_service_category, optional: true, class_name: 'Hmis::Hud::CustomServiceCategory'
  belongs_to :custom_service_type, optional: true, class_name: 'Hmis::Hud::CustomServiceType'

  scope :for_projects, -> { where(entity_type: Hmis::Hud::Project.sti_name) }
  scope :for_organizations, -> { where(entity_type: Hmis::Hud::Organization.sti_name) }
  scope :for_project_types, -> { where(entity_type: 'ProjectType') }
  scope :defaults, -> { where(entity_type: nil, entity_id: nil) }

  scope :for_project, ->(project_id) { for_projects.where(entity_id: project_id) }
  scope :for_organization, ->(organization_id) { for_organizations.where(entity_id: organization_id) }
  scope :for_project_type, ->(project_type) { for_project_types.where(entity_id: project_type) }

  scope :for_service_type, ->(service_type_id) { where(custom_service_type_id: service_type_id) }
  scope :for_service_category, ->(category_id) { where(custom_service_category_id: category_id) }

  scope :for_services, -> do
    fi_t = Hmis::Form::Instance.arel_table
    where(fi_t[:custom_service_type_id].not_eq(nil).or(fi_t[:custom_service_category_id].not_eq(nil)))
  end

  scope :for_project_through_entities, ->(project) do
    ids = Hmis::Form::Instance.for_project(project.id).pluck(:id)
    ids += Hmis::Form::Instance.for_organization(project.organization.id).pluck(:id)
    ids += Hmis::Form::Instance.for_project_type(project.project_type).pluck(:id)
    ids += defaults.pluck(:id)
    where(id: ids)
  end
end
