###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::Instance < ::GrdaWarehouseBase
  self.table_name = :hmis_form_instances

  # ! If entity is ProjectType, then using this association directly might cause issues since the ID points to an enum value, not an actual AR entity
  belongs_to :entity, polymorphic: true, optional: true
  belongs_to :definition, foreign_key: :identifier, primary_key: :form_definition_identifier

  scope :for_projects, -> { where(entity_type: 'Hmis::Hud::Project') }
  scope :for_organizations, -> { where(entity_type: 'Hmis::Hud::Organization') }
  scope :for_project_types, -> { where(entity_type: 'ProjectType') }
  scope :defaults, -> { where(entity_type: nil, entity_id: nil) }

  scope :for_project, ->(project_id) { for_projects.where(entity_id: project_id) }
  scope :for_organization, ->(organization_id) { for_organizations.where(entity_id: organization_id) }
  scope :for_project_type, ->(project_type) { for_project_types.where(entity_id: project_type) }
end
