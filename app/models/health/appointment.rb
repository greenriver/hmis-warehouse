module Health
  class Appointment < Base

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
  end
end
