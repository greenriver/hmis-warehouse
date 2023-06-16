###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp::PopulatePctpConcern
  extend ActiveSupport::Concern

  included do
    def populate_from_ca(user)
      ca = patient.recent_ca_assessment&.instrument
      return unless ca.present? && ca.is_a?(::HealthComprehensiveAssessment::Assessment)

      tc = if patient.care_coordinator.present?
        Health::UserCareCoordinator.find_by(care_coordinator_id: patient.care_coordinator.id)&.
          coordination_team&.
          team_coordinator
      end

      update(
        initial_date: Date.current,

        name: ca.name,
        dob: ca.dob,
        email: ca.email,
        phone: ca.phone,

        cc_name: patient.care_coordinator&.name,
        cc_phone: patient.care_coordinator&.phone,
        cc_email: patient.care_coordinator&.email,

        ccm_name: tc&.name,
        ccm_phone: tc&.phone,
        ccm_email: tc&.email,

        pcp_name: ca.pcp_provider,
        pcp_phone: ca.pcp_phone,
        pcp_email: ca.pcp_address,

        rn_name: patient.nurse_care_manager&.name,
        rn_phone: patient.nurse_care_manager&.phone,
        rn_email: patient.nurse_care_manager&.email,

        scribe: user.name,
        sex_at_birth: ca.sex_at_birth,
        sex_at_birth_other: ca.sex_at_birth_other,
        gender: ca.gender,
        gender_other: ca.gender_other,
        orientation: ca.orientation,
        orientation_other: ca.orientation_other,
        race: ca.race,
        ethnicity: ca.ethnicity,
        language: ca.language,
        contact: ca.contact,
        contact_other: ca.contact_other,

        strengths: ca.strengths,
        weaknesses: ca.weaknesses,
        interests: ca.interests,
        choices: ca.choices,
        care_goals: ca.care_goals,
        personal_goals: ca.personal_goals,
        cultural_considerations: ca.cultural_considerations,

        accessibility_equipment: ca.accessibility_equipment,
        accessibility_equipment_notes: ca.accessibility_equipment_notes,
        accessibility_equipment_start: ca.accessibility_equipment_start,
        accessibility_equipment_end: ca.accessibility_equipment_end,
      )
    end
  end
end
