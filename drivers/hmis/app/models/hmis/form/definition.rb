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

    base_scope = Hmis::Form::Instance.joins(:definition)
    base_scope = base_scope.where(definition: { role: role }) if role.present?
    [
      base_scope.for_project(project.id),
      base_scope.for_organization(project.organization.id),
      base_scope.for_project_type(project.project_type),
      base_scope.defaults,
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
    definitions.order(version: :desc).first
  end

  # Validate JSON definition when loading, to ensure no duplicate link IDs
  def self.validate_json(json)
    seen_link_ids = Set.new

    recur_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        link_id = child_item['link_id']
        raise "Missing link ID: #{child_item}" unless link_id.present?

        raise "Duplicate link ID: #{link_id}" if seen_link_ids.include?(link_id)

        seen_link_ids.add(link_id)
        recur_check.call(child_item)
      end
    end

    recur_check.call(json)
  end

  # Unused
  def apply_conditionals(enrollment)
    parsed = JSON.parse(definition)
    client = enrollment.client
    parsed['item'].delete_if { |item| irrelevant_item?(item, enrollment, client) }
    self.definition = parsed.to_json
  end

  private def irrelevant_item?(item, enrollment, client)
    condition = item['data_collected_about']
    return !matches_condition(condition, enrollment, client) if condition.present?

    # TODO: check project type condition
    # TODO: check funder condition

    item['item'].delete_if { |child| irrelevant_item?(child, enrollment, client) } if item['item'].present?

    false
  end

  private def matches_condition(condition, enrollment, client)
    case condition
    when 'ALL_CLIENTS'
      true
    when 'HOH'
      enrollment.RelationshipToHoH == 1
    when 'HOH_AND_ADULTS'
      enrollment.RelationshipToHoH == 1 || client.age >= 18
    else
      raise NotImplementedError
    end
  end
end
