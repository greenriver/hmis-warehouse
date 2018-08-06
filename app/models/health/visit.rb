module Health
  class Visit < EpicBase

    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :visits

    self.source_key = :ENC_ID

    def self.csv_map(version: nil)
      {
        PAT_ID: :patient_id,
        ENC_ID: :id_in_source,
        date_of_service: :date_of_service,
        department: :department,
        type: :visit_type,
        provider: :provider,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end
  end
end
