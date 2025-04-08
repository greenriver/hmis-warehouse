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

      units = Hmis::Unit.preload(:unit_type, :current_occupants, :active_opportunity).where(id: unit_ids)
      raise 'Not found' unless units.any?

      projects = units.pluck(:project_id).uniq
      raise 'Not found' if projects.empty?
      raise 'Cannot manage units across projects' if projects.size > 1

      project = Hmis::Hud::Project.find_by(id: projects.first)
      raise 'Access denied' unless current_user.permissions_for?(project, :can_manage_units)

      # TODO(#7522) - template should be determined by context (project, unit type, ...)
      # For now, if you are using the "starter pack," this picks the template that creates an enrollment
      template = Hmis::WorkflowDefinition::Template.last
      raise unless template.present?

      Hmis::Unit.transaction do
        opportunities = units.map do |unit|
          mark_available(unit, template)
        end

        Hmis::Ce::Opportunity.import!(opportunities)
      end

      { units: Hmis::Unit.where(id: unit_ids) } # we don't need the preloads this time, so fresh query instead of reload
    end

    private

    def mark_available(unit, template)
      raise 'Currently occupied unit cannot be marked available' if unit.current_occupants.any?
      raise 'Unit already has an opportunity' if unit.active_opportunity.present?

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
