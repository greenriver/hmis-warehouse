###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Appointment < EpicBase
    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier, "ID of Appointment"
    phi_attr :notes, Phi::FreeText, "Notes of appointment"
    phi_attr :doctor, Phi::SmallPopulation, "Name of Doctor"
    phi_attr :department, Phi::SmallPopulation, "Name of department"
    phi_attr :sa, Phi::NeedsReview
    phi_attr :appointment_time, Phi::Date, "Date of appointment"
    phi_attr :id_in_source, Phi::OtherIdentifier

    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :appointments, optional: true
    scope :limited, -> do
      where.not(department: ignore_departments)
    end

    self.source_key = :ENC_ID

    def self.csv_map(version: nil)
      {
        PAT_ID: :patient_id,
        ENC_ID: :id_in_source,
        datetime: :appointment_time,
        type: :appointment_type,
        notes: :notes,
        doctor: :doctor,
        department: :department,
        sa: :sa,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end

    def self.ignore_departments
      [
        'BHC MCINNIS HOUSE',
        'BHC KIRKPATRICK HOUSE',
      ]
    end

    def clean_row row:, data_source_id:
      # these don't include timezone data, using Time.parse puts it in
      # the local timezone with the correct time.
      row['datetime'] = Time.parse(row['datetime']) rescue nil
      row
    end
  end
end
