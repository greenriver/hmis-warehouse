###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Risk: Describes a patient and contains PHI
# Control: PHI attributes documented

module Health
  class EncounterRecord < HealthBase
    belongs_to :encounter_report, optional: true

    phi_patient :medicaid_id
    phi_attr :date, Phi::Date, "Date of encouter"
    phi_attr :provider_name, Phi::SmallPopulation, "Name of provider"
    phi_attr :contact_reached, Phi::SmallPopulation, "Whether contact is reached"
    phi_attr :mode_of_contact, Phi::SmallPopulation, "Mode of contact"
    phi_attr :dob, Phi::Date, "Date of birth of patient"
    phi_attr :gender, Phi::SmallPopulation, "Gender of patient"
    phi_attr :race, Phi::SmallPopulation, "Race of patient"
    phi_attr :ethnicity, Phi::SmallPopulation, "Ethnicity of patient"
    phi_attr :veteran_status, Phi::SmallPopulation, "Veteran status of patient"
    phi_attr :housing_status, Phi::SmallPopulation, "Housing status of patient"
    phi_attr :source, Phi::SmallPopulation, "Source of encouter"
    phi_attr :encounter_type, Phi::SmallPopulation, "Type of encouter"
  end
end
