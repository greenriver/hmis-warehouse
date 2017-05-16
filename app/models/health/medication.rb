module Health
  class Medication < HealthBase

    belongs_to :patient

    def self.csv_map(version: nil)
      {
        PAT_ID: :patient_id,
        OM_ID: :id_in_source,
        name: :name,
        start_date: :start_date,
        ordered_date: :ordered_date,
        instructions: :instructions,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end
  end
end
