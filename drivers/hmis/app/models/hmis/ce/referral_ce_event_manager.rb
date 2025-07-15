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

      target_project = referral.target_project

      enrollment.events.create!(
        event_date: Date.current,
        event: project_to_event_type(target_project), # TODO(#7527) determine event type from configuration if present
        location_crisis_or_ph_housing: target_project.id, # TODO(#7954) add target project ID reference column to Event
        user: Hmis::Hud::User.from_user(message.user),
      )
    end

    def set_ce_event_result(message) # rubocop:disable Naming/AccessorMethodName
      enrollment = referral.source_enrollment
      event_type = project_to_event_type(referral.target_project)
      event = enrollment.events.where(event: event_type).order(:date_created).last # TODO(#7954) add referral reference and use it to find the correct CE Event
      raise "Expected to find CE event of type #{event_type} for enrollment #{enrollment.id}" unless event

      referral_result = message.params['referral_result']&.to_i
      raise "Invalid referral result #{referral_result} submitted for referral #{referral.id} probably indicates misconfigured workflow or form definition" unless HudUtility2024.referral_results.keys.include?(referral_result)

      event.update!(
        result_date: Date.current,
        referral_result: referral_result,
      )
    end

    private

    def project_to_event_type(project)
      event_type = HudUtility2026.project_to_ce_event_type(project)
      raise "Unexpected target project type #{project_type} on project #{project.id} for referral #{referral.id}" unless event_type

      event_type
    end
  end
end
