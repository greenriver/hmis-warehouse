###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EdIpVisitFile < HealthBase
    acts_as_paranoid
    require 'csv'

    phi_attr :file, Phi::FreeText
    phi_attr :content, Phi::FreeText

    belongs_to :user

    mount_uploader :file, EdIpVisitFileUploader

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

    belongs_to :patient, primary_key: :medicaid_id, foreign_key: :medicaid_id
    has_many :ed_ip_visits

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

    def create_visits!
      if check_header
        ::CSV.parse(content, headers: true) do |row|
          model_row = {
            ed_ip_visit_file_id: self.id,
          }
          self.class.header_map.each do |column, title|
            model_row[column] = row[title]
          end
          Health::EdIpVisit.create(model_row)
        end
        return true
      else
        return false
      end
    end

    def label
      type
    end

    def columns
      self.class.header_map
    end

    private def check_header
      incoming = ::CSV.parse(content.lines.first).flatten.map{|m| m&.strip}
      expected = parsed_expected_header.map{|m| m&.strip}
      # You can update the header string with File.read('path/to/file.csv').lines.first
      # Using CSV parse in case the quoting styles differ
      if incoming == expected
        return true
      else

        Rails.logger.error (incoming - expected).inspect
        Rails.logger.error (expected - incoming).inspect
      end
      return false
    end

    private def parsed_expected_header
      CSV.parse(expected_header).flatten
    end

    def label
      'ED & IP Visits'
    end

    private def expected_header
      self.class.header_map.values.join(',')
    end
  end
end