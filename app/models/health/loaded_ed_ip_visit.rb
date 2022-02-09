###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class LoadedEdIpVisit < HealthBase
    acts_as_paranoid

    phi_patient :medicaid_id
    phi_attr :last_name, Phi::Name, 'Last name of patient'
    phi_attr :first_name, Phi::Name, 'First name of patient'
    phi_attr :gender, Phi::SmallPopulation, 'Gender of patient'
    phi_attr :dob, Phi::Date, 'Date of birth of patient'
    phi_attr :admit_date, Phi::Date, 'Date of admission'
    phi_attr :discharge_date, Phi::Date, 'Date of discharge'
    phi_attr :discharge_disposition, Phi::FreeText, 'Disposition of discharge'
    phi_attr :encounter_major_class, Phi::SmallPopulation, 'Emergency or Inpatient'
    phi_attr :visit_type, Phi::SmallPopulation, 'Type of visit'
    phi_attr :encounter_facility, Phi::SmallPopulation, 'Facility of encounter'
    phi_attr :chief_complaint_diagnosis, Phi::FreeText, 'Description of diagnosis of chief complaint'
    phi_attr :attending_physician, Phi::SmallPopulation, 'Name of attending physician'
    phi_attr :member_record_number, Phi::MedicalRecordNumber, 'Identifier from facility'
    phi_attr :patient_identifier, Phi::OtherIdentifier, 'Identifier from facility'
    phi_attr :patient_url, Phi::OtherIdentifier, 'URL may contain unique patient identifier'
    phi_attr :admitted_inpatient, Phi::SmallPopulation, 'Was the patient admitted?'

    belongs_to :patient, primary_key: :medicaid_id, foreign_key: :medicaid_id, optional: true
    belongs_to :ed_ip_visit_file
    has_one :ed_ip_visit, dependent: :destroy

    scope :from_file, ->(file) do
      where(ed_ip_visit_file_id: file.id)
    end
  end
end
