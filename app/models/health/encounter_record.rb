###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Risk: Describes a patient and contains PHI
# Control: PHI attributes documented

module Health
  class EncounterRecord < HealthBase
    belongs_to :encounter_report

    phi_patient :medicaid_id
    phi_attr :date, Phi::Date
    phi_attr :provider_name, Phi::SmallPopulation
    phi_attr :contact_reached, Phi::SmallPopulation
    phi_attr :mode_of_contact, Phi::SmallPopulation
    phi_attr :dob, Phi::Date
    phi_attr :gender, Phi::SmallPopulation
    phi_attr :race, Phi::SmallPopulation
    phi_attr :ethnicity, Phi::SmallPopulation
    phi_attr :veteran_status, Phi::SmallPopulation
    phi_attr :housing_status, Phi::SmallPopulation
    phi_attr :source, Phi::SmallPopulation
    phi_attr :encounter_type, Phi::SmallPopulation
  end
end