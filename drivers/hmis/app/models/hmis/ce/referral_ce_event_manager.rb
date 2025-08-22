###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce
  class ReferralCeEventManager
    attr_reader :referral

    def initialize(referral)
      @referral = referral
    end

    def create_ce_event(message)
      enrollment = referral.source_enrollment
      raise 'Referral does not have a source enrollment' unless enrollment.present?

      # If the referral already has a CE event, return early and don't raise
      return if referral.ce_event.present?

      target_project = referral.target_project

      enrollment.events.create!(
        event_date: Date.current,
        event: determine_event_type,
        location_crisis_or_ph_housing: target_project.id, # TODO(#7954) add target project ID reference column to Event
        user: Hmis::Hud::User.from_user(message.user),
        ce_referral_id: referral.id,
      )
    end

    def set_ce_event_result(message) # rubocop:disable Naming/AccessorMethodName
      event = referral.ce_event
      raise "Expected to find CE event for referral #{referral.id}" unless event

      referral_result = message.params['referral_result']&.to_i
      raise "Invalid referral result #{referral_result} submitted for referral #{referral.id} probably indicates misconfigured workflow or form definition" unless HudUtility2024.referral_results.keys.include?(referral_result)

      event.update!(
        result_date: Date.current,
        referral_result: referral_result,
      )
    end

    private

    def determine_event_type
      # Check if there's a configured ce_event_type on the unit group
      unit_group = referral.opportunity.unit&.unit_group
      return unit_group.ce_event_type if unit_group&.ce_event_type.present?

      # Fall back to determining the event type based on the referral target project
      project = referral.target_project
      event_type = HudUtility2026.project_to_ce_event_type(project)
      raise "Unable to determine CE Event Type for project type #{project.project_type} on project #{project.id} for referral #{referral.id}" unless event_type

      event_type
    end
  end
end
