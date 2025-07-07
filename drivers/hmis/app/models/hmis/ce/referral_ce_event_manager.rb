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

    def project_to_event_type(project) # Logic is from Data Dictionary 4.20.2 Coordinated Entry Event
      project_type = project.project_type

      es_types = HudUtility2024.residential_project_type_numbers_by_code[:es] + HudUtility2024.residential_project_type_numbers_by_code[:sh]
      return HudUtility2024.ce_events_by_code[:es] if es_types.include?(project_type)

      th_rrh_types = HudUtility2024.residential_project_type_numbers_by_code[:th] + HudUtility2024.residential_project_type_numbers_by_code[:rrh]
      if th_rrh_types.include?(project_type)
        # If the project has specific open funders, record this as a joint TH/RRH event. (12)
        return HudUtility2024.ce_events_by_code[:th_rrh] if project.funders.open_on_date.where(funder: HudUtility2024.ce_event_joint_th_rrh_funders).any?

        # Otherwise, record the event corresponding to the project type (11 or 13)
        return HudUtility2024.ce_events_by_code[:th] if HudUtility2024.residential_project_type_numbers_by_code[:th].include?(project_type)
        return HudUtility2024.ce_events_by_code[:rrh] if HudUtility2024.residential_project_type_numbers_by_code[:rrh].include?(project_type)
      end

      psh_types = HudUtility2024.residential_project_type_numbers_by_code[:psh]
      return HudUtility2024.ce_events_by_code[:psh] if psh_types.include?(project_type)

      oph_types = HudUtility2024.residential_project_type_numbers_by_code[:oph]
      return HudUtility2024.ce_events_by_code[:oph] if oph_types.include?(project_type)

      raise "Unexpected target project type #{project_type} on project #{project.id} for referral #{referral.id}"
    end
  end
end
