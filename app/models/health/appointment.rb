module Health
  class Appointment < EpicBase
    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier
    phi_attr :date_of_service, Phi::Date
    phi_attr :appointment_time, Phi::Date
    phi_attr :notes, Phi::FreeText
    phi_attr :doctor, Phi::SmallPopulation
    phi_attr :id_in_source, Phi::OtherIdentifier
    phi_attr :sa, Phi::NeedsReview

    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :appointments
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
