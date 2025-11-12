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
      # Skip CE Event creation if source Enrollment is missing. (Expected for VSP referrals or if the source enrollment was deleted)
      return unless enrollment

      # If the referral already has a CE event, return early and don't raise
      return if referral.ce_event.present?

      # If there is no CE event type for this project/unit group, return without creating a CE event
      event_type = determine_event_type
      return unless event_type

      enrollment.events.create!(
        event_date: Date.current,
        event: event_type,
        location_crisis_or_ph_housing: referral.target_project.id, # TODO(#7954) add target project ID reference column to Event
        user: Hmis::Hud::User.from_user(message.user),
        ce_referral: referral,
      )
    end

    def set_ce_event_result(message) # rubocop:disable Naming/AccessorMethodName
      # If there is no event type determined for this project/unit group, that indicates CE event wasn't created
      event_type = determine_event_type(capture_to_sentry: false) # No need to capture to Sentry a second time
      return unless event_type

      # If CE Event Type can be determined, but CE Event is missing, raise.
      # This indicates the workflow is misconfigured because CE Event Creation should have occurred already.
      event = referral.ce_event
      raise "Expected to find CE event for referral #{referral.id}" unless event

      referral_result = message.params['referral_result']&.to_i
      raise "Invalid referral result #{referral_result} submitted for referral #{referral.id} probably indicates misconfigured workflow or form definition" unless HudHelper.util.referral_results.keys.include?(referral_result)

      event.update!(
        result_date: Date.current,
        referral_result: referral_result,
      )
    end

    private

    def determine_event_type(capture_to_sentry: true)
      # Check if there's a configured ce_event_type on the unit group
      unit_group = referral.opportunity.unit&.unit_group
      return unit_group.ce_event_type if unit_group&.ce_event_type.present?

      # Fall back to determining the event type based on the referral target project
      project = referral.target_project
      event_type = HudHelper.util('2026').project_to_ce_event_type(project)
      if capture_to_sentry && !event_type
        # Log to Sentry without raising. This is expected for projects that reuse a workflow from another project, but don't need to generate a CE event.
        Sentry.capture_message("Unable to determine CE Event Type for project type #{project.project_type} on project #{project.id} for referral #{referral.id}")
      end
      event_type
    end
  end
end
