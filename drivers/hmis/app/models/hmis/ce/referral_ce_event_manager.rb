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

      # todo @martha - data dictionary says: where 2.09.2 Project Receives CE Referrals = "Yes" as of the "Date of event"
      # raise unless referral.target_project.ce_participations.any?

      enrollment.events.create!(
        event_date: Date.current,
        event: project_to_event_type(target_project), # TODO(#7527) determine event type from configuration if present
        location_crisis_or_ph_housing: target_project.id,
        user: Hmis::Hud::User.from_user(message.user),
      )
    end

    def set_ce_event_result(message) # rubocop:disable Naming/AccessorMethodName
      enrollment = referral.source_enrollment
      event_type = project_to_event_type(referral.target_project)
      event = enrollment.events.where(event: event_type).first
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
      case project.project_type
      when *(HudUtility2024.residential_project_type_numbers_by_code[:es] + HudUtility2024.residential_project_type_numbers_by_code[:sh])
        HudUtility2024.ce_events_by_code[:es]
      when *(HudUtility2024.residential_project_type_numbers_by_code[:th] + HudUtility2024.residential_project_type_numbers_by_code[:rrh])
        # todo @martha - fix and test logic
        # AND the presence of an open funder 44, 54 or 55 (see data dict)
        # if it's either one of these AND has a specific funder, on date event_date, then
        # HudUtility2024.ce_events_by_code[:th_rrh]
        # else if it's th,
        # then HudUtility2024.ce_events_by_code[:th]
        # else if it's rrh,
        # then  HudUtility2024.ce_events_by_code[:rrh]
      when *HudUtility2024.residential_project_type_numbers_by_code[:psh]
        HudUtility2024.ce_events_by_code[:psh]
      when *HudUtility2024.residential_project_type_numbers_by_code[:oph]
        HudUtility2024.ce_events_by_code[:oph]
      else
        raise "Unexpected target project type #{project.project_type} on project #{project.id} for referral #{referral.id}"
      end
    end
  end
end
