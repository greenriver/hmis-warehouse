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
      access_denied! unless policy_for(project, policy_type: :hmis_project).can_update_unit_availability?

      # Validate that units being marked available don't exceed assigned legacy ReferralPostings
      validate_unit_availability_against_referral_postings(units, project)

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
        candidate_pool_id: unit_group.candidate_pool_id,
        assignment_rules: rule_resolver.rules_for_unit_group(unit_group).map(&:attributes),
      )
    end

    def rule_resolver
      @rule_resolver ||= Hmis::Ce::Match::UnitGroupRuleResolver.new
    end

    # Validate that the units being marked available don't exceed assigned legacy ReferralPostings.
    # This is a temporary fix for issue #8359.
    # This is in place for systems where legacy ReferralPostings and CE Referrals coexist during a transition period,
    # and can be removed once referral postings are removed from the system.
    def validate_unit_availability_against_referral_postings(units, project)
      return unless project.external_referral_postings.active.exists? # early return if no active legacy ReferralPostings

      # Count units being marked available by unit type
      num_units_by_type = units.map(&:unit_type_id).tally

      num_units_by_type.each do |unit_type_id, num_units_being_marked|
        next if unit_type_id.nil? # Skip units without unit type

        # Count total vacant units for this unit type in this project
        vacant_units_count = project.units.unoccupied_on.with_unit_type(unit_type_id).count
        # Units that are already receiving referrals
        accepting_referrals_count = project.units.receiving_referrals.with_unit_type(unit_type_id).count

        # Count 'assigned' and 'denied pending' ReferralPostings for this unit type in this project.
        # Note: 'accepted pending' is not counted because accepted pending postings have an associated enrollment that is already placed in a unit.
        assigned_postings_count = project.external_referral_postings.
          where(unit_type_id: unit_type_id, status: ['assigned_status', 'denied_pending_status']).
          count

        # Calculate how many units can be marked available: vacant units - assigned postings
        max_available_units = vacant_units_count - assigned_postings_count - accepting_referrals_count
        max_available_units = [max_available_units, 0].max # if already over-requested, max is 0

        # Skip if we're not trying to mark more units available than allowed
        next unless num_units_being_marked > max_available_units

        # Raise user-facing error if we're trying to mark more units available than allowed.
        # (Raising instead of returning a validation error because validation errors not supported by the frontend in this UI, and this is a temporary fix.)
        unit_type = Hmis::UnitType.find(unit_type_id)
        msg = "Cannot mark #{num_units_being_marked} #{unit_type.description} units as available because of overlapping legacy Referral Postings. At most #{max_available_units} #{unit_type.description} units can be marked available at this time."
        raise HmisErrors::ApiError.new(msg, display_message: msg)
      end
    end
  end
end
