###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class Ce::MarkUnitsAvailable < CleanBaseMutation
    argument :unit_ids, [ID], required: true
    field :units, [Types::HmisSchema::Unit], null: false

    def resolve(unit_ids:)
      raise unless Hmis::Ce.configuration.enabled?

      units = Hmis::Unit.preload(:unit_type, :current_occupants, :opportunities, :latest_opportunity, unit_group: :workflow_template).where(id: unit_ids)
      raise 'Not found' unless units.any?

      project_ids = units.map(&:project_id).uniq
      raise 'Not found' if project_ids.empty?
      raise 'Cannot manage units across projects' if project_ids.size > 1

      project = Hmis::Hud::Project.find_by(id: project_ids.first)
      access_denied! unless policy_for(project, policy_type: :hmis_project).can_manage_units?

      opportunities = units.map { |unit| build_opportunity_for_unit(unit) }
      Hmis::Ce::Opportunity.import!(opportunities)

      { units: Hmis::Unit.where(id: unit_ids) } # we don't need the preloads this time, so fresh query instead of reload
    end

    private

    def build_opportunity_for_unit(unit)
      raise 'Unit already has an active opportunity' if unit.latest_opportunity&.active?

      unit_group = unit.unit_group
      raise 'Unit must be in a Unit Group to be marked available' unless unit_group

      workflow_template = unit_group.workflow_template
      raise 'Unit Group has no Workflow Template' unless workflow_template

      unit_desc = unit.unit_type&.description
      opportunity_name = "Unit #{unit.id}#{unit_desc ? ' - ' : ''}#{unit_desc}"

      Hmis::Ce::Opportunity.new(
        unit: unit,
        project: unit.project,
        name: opportunity_name,
        workflow_template_identifier: workflow_template.identifier,
        candidate_pool_id: unit_group.candidate_pool_id,
        assignment_rules: rule_resolver.rules_for_unit_group(unit_group).map(&:attributes),
      )
    end

    def rule_resolver
      @rule_resolver ||= Hmis::Ce::Match::UnitGroupRuleResolver.new
    end
  end
end
