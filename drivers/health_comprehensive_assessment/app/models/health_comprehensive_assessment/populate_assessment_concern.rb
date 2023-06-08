###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthComprehensiveAssessment::PopulateAssessmentConcern
  extend ActiveSupport::Concern

  included do
    def populate_from_patient
      pcp = provider.team_members.detect { |member| member.is_a?(Health::Team::Provider) || member.is_a?(Health::Team::PcpDesignee) }

      update(
        name: patient.name,
        dob: patient.dob,
        disabled: patient.client.currently_disabled? ? 'yes' : 'no',
        pcp_provider: pcp&.full_name,
        pcp_address: pcp&.email,
        pcp_phone: pcp&.phone,
        accessibility_equipment_start: Date.current,
      )

      patient.medications.each do |medication|
        medications.create(
          medication: medication.name,
          dosage: medication.instructions,
        )
      end
    end
  end
end
