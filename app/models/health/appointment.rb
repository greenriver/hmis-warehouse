module Health
  class Appointment < HealthBase

    belongs_to :patient

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
  end
end
