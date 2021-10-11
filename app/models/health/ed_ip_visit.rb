###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EdIpVisit < HealthBase
    acts_as_paranoid

    phi_patient :medicaid_id
    phi_attr :last_name, Phi::Name, "Last name of patient"
    phi_attr :first_name, Phi::Name, "First name of patient"
    phi_attr :gender, Phi::SmallPopulation, "Gender of patient"
    phi_attr :dob, Phi::Date, "Date of birth of patient"
    phi_attr :admit_date, Phi::Date, "Date of admission"
    phi_attr :discharge_date, Phi::Date, "Date of discharge"
    phi_attr :discharge_disposition, Phi::FreeText, "Disposition of discharge"
    phi_attr :encounter_major_class, Phi::SmallPopulation
    phi_attr :visit_type, Phi::SmallPopulation, "Type of visit"
    phi_attr :encounter_facility, Phi::SmallPopulation, "Facility of encouter"
    phi_attr :chief_complaint_diagnosis, Phi::FreeText, "Description of diagnosis of chief complaint"
    phi_attr :attending_physician, Phi::SmallPopulation, "Name of attending physician"

    belongs_to :patient, primary_key: :medicaid_id, foreign_key: :medicaid_id, optional: true
    belongs_to :ed_ip_visit_file, optional: true

    scope :valid, -> do
      where.not(admit_date: nil, visit_type: nil)
    end

    def self.header_map
      {
        medicaid_id: 'Medicaid',
        last_name: 'Last Name',
        first_name: 'First Name',
        gender: 'Gender',
        dob: 'DOB',
        admit_date: 'Admit Date',
        discharge_date: 'Discharge Date',
        discharge_disposition: 'Discharge Disposition',
        encounter_major_class: 'Encounter Major Class',
        visit_type: 'Visit Type',
        encounter_facility: 'Encounter Facility',
        chief_complaint_diagnosis: 'Chief Complaint Diagnosis',
        attending_physician: 'Attending Physician',
      }
    end
  end
end
