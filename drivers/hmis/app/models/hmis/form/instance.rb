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

  validates :data_collected_about, inclusion: { in: Types::Forms::Enums::DataCollectedAbout.values.keys }

  # 'system' instances can't be deleted
  scope :system, -> { where(system: true) }
  scope :not_system, -> { where(system: false) }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  scope :for_projects, -> { where(entity_type: Hmis::Hud::Project.sti_name) }
  scope :for_organizations, -> { where(entity_type: Hmis::Hud::Organization.sti_name) }
  scope :defaults, -> do
                     where(
                       entity_type: nil,
                       entity_id: nil,
                       # ok to remove this?
                       #  custom_service_type_id: nil,
                       #  custom_service_category_id: nil,
                       funder: nil,
                       other_funder: nil,
                       project_type: nil,
                     )
                   end

  # Find instances that are for a specific Project
  scope :for_project, ->(project_id) { for_projects.where(entity_id: project_id) }

  # Find instances that are for a specific Organization
  scope :for_organization, ->(organization_id) { for_organizations.where(entity_id: organization_id) }

  # Find instances that match a project based on Project Type _and_ Funder
  scope :for_project_by_funder_and_project_type, ->(project) do
    funders = project.funders.pluck(:funder).compact
    return none unless funders.any? && project.project_type.present?

    where(fi_t[:project_type].eq(project.project_type).and(fi_t[:funder].in(funders)))
  end

  # Find instances that match a project based on Funder
  scope :for_project_by_funder, ->(project) do
    funders = project.funders.pluck(:funder).compact
    return none unless funders.any?

    # Excludes instances where project type is specified. If funder and project type are
    # both present, they must BOTH match for the instance to be used.
    where(fi_t[:funder].in(funders).and(fi_t[:project_type].eq(nil)))
  end

  # Find instances that match a project based on Funder
  scope :for_project_by_project_type, ->(project_type) do
    return none if project_type.nil?

    # Excludes instances where funder is specified. If funder and project type are
    # both present, they must BOTH match for the instance to be used.
    where(fi_t[:project_type].eq(project_type).and(fi_t[:funder].eq(nil)))
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
    # From most specific => least specific
    ids = Hmis::Form::Instance.for_project(project.id).pluck(:id)
    ids += Hmis::Form::Instance.for_organization(project.organization.id).pluck(:id)
    ids += Hmis::Form::Instance.for_project_by_funder_and_project_type(project).pluck(:id)
    ids += Hmis::Form::Instance.for_project_by_funder(project).pluck(:id)
    ids += Hmis::Form::Instance.for_project_by_project_type(project.project_type).pluck(:id)
    ids += defaults.pluck(:id)
    where(id: ids)
  end

  # Sort by specificity group, with a tie-breaker on date updated (more recent preferred)
  def self.sort_by_specificity(instance_array)
    instance_array.sort_by do |inst|
      has_funder = inst.funder.present? || inst.other_funder.present?

      # 1: associated directly to project
      specificity = if inst.entity_id.present? && inst.entity_type == 'Hmis::Hud::Project'
        1
      # 2: associated directly to org
      elsif inst.entity_id.present? && inst.entity_type == 'Hmis::Hud::Organization'
        2
      # 3: associated to project type and funder
      elsif inst.project_type.present? && has_funder
        3
      # 4: associated to funder
      elsif has_funder
        4
      # 5: associated to project_type
      elsif inst.project_type.present?
        5
      # default
      else
        1000
      end

      [
        inst.active == true ? 0 : 1, # Put active instances before inactive ones
        specificity, # Put more specific instances first
        Time.current - inst.updated_at, # Tie breaker: choose more recently updated
      ]
    end
  end
end
