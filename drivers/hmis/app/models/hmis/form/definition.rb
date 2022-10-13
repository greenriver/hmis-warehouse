###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::Definition < ::GrdaWarehouseBase
  self.table_name = :hmis_form_definitions

  has_many :instances, foreign_key: :identifier, primary_key: :form_definition_identifier
  has_many :assessment_details

  def self.definitions_for_project(project, role: nil)
    instance_scope = Hmis::Form::Instance.none

    [
      Hmis::Form::Instance.for_project(project.id),
      Hmis::Form::Instance.for_organization(project.organization.id),
      Hmis::Form::Instance.for_project_type(project.project_type),
      Hmis::Form::Instance.defaults,
    ].each do |scope|
      next if instance_scope.present?

      instance_scope = scope unless scope.empty?
    end

    definitions = where(identifier: instance_scope.pluck(:definition_identifier))
    definitions = definitions.where(role: role) if role.present?

    definitions
  end

  def self.find_definition_for_project(project, role:, version: nil)
    definitions = definitions_for_project(project, role: role)
    definitions = definitions.where(version: version) if version.present?
    definitions.order(version: :asc).first
  end
end
