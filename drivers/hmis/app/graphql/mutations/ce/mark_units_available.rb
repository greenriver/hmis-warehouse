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
      access_denied! unless current_user.permissions_for?(project, :can_manage_units)

      # Determine which template to use for each unit based on Unit Group configuration.
      unit_to_template = units.preload(unit_group: :workflow_template).map do |unit|
        workflow_template = unit.unit_group&.workflow_template # load Workflow Template record to validate it exists
        raise 'Unable to mark unit available because there is no associated workflow template' unless workflow_template

        [unit.id, workflow_template]
      end.to_h

      candidate_pool_resolver = Hmis::Ce::Match::CandidatePoolResolver.new

      Hmis::Unit.transaction do
        opportunities = units.map do |unit|
          template = unit_to_template.fetch(unit.id)
          build_opportunity_for_unit(unit, template, candidate_pool_resolver)
        end

        result = Hmis::Ce::Opportunity.import!(opportunities)
        Hmis::Ce::BuildCandidatePoolsJob.perform_later(opportunity_ids: result.ids)
      end

      { units: Hmis::Unit.where(id: unit_ids) } # we don't need the preloads this time, so fresh query instead of reload
    end

    private

    def build_opportunity_for_unit(unit, template, candidate_pool_resolver)
      raise 'Unit already has an active opportunity' if unit.latest_opportunity&.active?

      unit_desc = unit.unit_type&.description
      opportunity_name = "Unit #{unit.id}#{unit_desc ? ' - ' : ''}#{unit_desc}"

      opportunity = Hmis::Ce::Opportunity.new(
        unit: unit,
        project: unit.project,
        name: opportunity_name,
        workflow_template_identifier: template.identifier,
      )

      opportunity.candidate_pool = candidate_pool_resolver.candidate_pool_for_opportunity(opportunity: opportunity)
      opportunity
    end
  end
end
