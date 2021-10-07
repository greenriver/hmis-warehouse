###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EdIpVisitFileV2 < EdIpVisitFile
    acts_as_paranoid

    def label
      'ED & IP Visits (V2)'
    end

    def self.header_map
      {
        first_name: 'First Name',
        last_name: 'Last Name',
        member_record_number: 'Member Record Number',
        patient_identifier: 'Patient ID',
        dob: 'Date of Birth',
        patient_url: 'Patient URL',
        admit_date: 'Admit Date',
        encounter_major_class: 'Visit Major Class',
        visit_type: 'Visit Type',
        encounter_facility: 'Visit Facility',
        admitted_inpatient: 'Admitted Inpatient',
      }
    end

    def csv_date_columns
      @csv_date_columns ||= [
        :dob,
        :admit_date,
      ]
    end
  end
end
