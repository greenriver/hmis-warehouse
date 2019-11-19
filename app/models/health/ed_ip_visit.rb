###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EdIpVisit < HealthBase
    acts_as_paranoid

    phi_patient :medicaid_id
    phi_attr :last_name, Phi::Name
    phi_attr :first_name, Phi::Name
    phi_attr :gender, Phi::SmallPopulation
    phi_attr :dob, Phi::Date
    phi_attr :admit_date, Phi::Date
    phi_attr :discharge_date, Phi::Date
    phi_attr :discharge_disposition, Phi::FreeText
    phi_attr :encounter_major_class, Phi::SmallPopulation
    phi_attr :visit_type, Phi::SmallPopulation
    phi_attr :encounter_facility, Phi::SmallPopulation
    phi_attr :chief_complaint_diagnosis, Phi::FreeText
    phi_attr :attending_physician, Phi::SmallPopulation

    belongs_to :patient, primary_key: :medicaid_id, foreign_key: :medicaid_id, optional: true

    def self.header_map
      {
        medicaid_id: Medicaid,
        last_name: Last Name,
        first_name: First Name,
        gender: Gender,
        dob: DOB,
        admit_date: Admit Date,
        discharge_date: Discharge Date,
        discharge_disposition: Discharge Disposition,
        encounter_major_class: Encounter Major Class,
        visit_type: Visit Type,
        encounter_facility: Encounter Facility,
        chief_complaint_diagnosis: Chief Complaint Diagnosis,
        attending_physician: Attending Physician,
      }
    end
  end
end