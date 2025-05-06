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

      units = Hmis::Unit.preload(:unit_type, :current_occupants, :opportunities, :latest_opportunity).where(id: unit_ids)
      raise 'Not found' unless units.any?

      project_ids = units.pluck(:project_id).uniq
      raise 'Not found' if project_ids.empty?
      raise 'Cannot manage units across projects' if project_ids.size > 1

      project = Hmis::Hud::Project.find_by(id: project_ids.first)
      raise 'Access denied' unless current_user.permissions_for?(project, :can_manage_units)

      # TODO(#7522) - template should be determined by context (project, unit type, ...)
      # For now, if you are using the "starter pack," this picks the template that creates an enrollment
      template = Hmis::WorkflowDefinition::Template.last
      raise unless template.present?

      Hmis::Unit.transaction do
        opportunities = units.map do |unit|
          build_opportunity_for_unit(unit, template)
        end

        result = Hmis::Ce::Opportunity.import!(opportunities)
        opportunity_ids = result.ids
        Hmis::MatchCandidatesJob.perform_later(opportunity_ids: opportunity_ids, backoff_time: 24.hours)
      end

      { units: Hmis::Unit.where(id: unit_ids) } # we don't need the preloads this time, so fresh query instead of reload
    end

    private

    def build_opportunity_for_unit(unit, template)
      raise 'Unit already has an active opportunity' if unit.latest_opportunity&.active?

      unit_desc = unit.unit_type&.description
      opportunity_name = "Unit #{unit.id}#{unit_desc ? ' - ' : ''}#{unit_desc}"

      Hmis::Ce::Opportunity.new(
        owner: unit,
        project: unit.project,
        name: opportunity_name,
        workflow_template: template,
      )
    end
  end
end
