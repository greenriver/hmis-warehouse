module Health
  class Visit < HealthBase

    belongs_to :patient

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
