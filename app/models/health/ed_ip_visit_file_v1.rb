###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EdIpVisitFileV1 < EdIpVisitFile
    acts_as_paranoid

    def label
      'ED & IP Visits (V1)'
    end

    def self.header_map
      {
        medicaid_id: 'Medicaid ID',
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
        chief_complaint: 'Chief Complaint',
        diagnosis: 'Diagnosis',
        attending_physician: 'Attending Physician',
      }
    end

    def csv_date_columns
      @csv_date_columns ||= [
        :dob,
        :admit_date,
        :discharge_date,
      ]
    end
  end
end
