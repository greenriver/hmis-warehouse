module Health
  class Medication < EpicBase

    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :medications

    self.source_key = :OM_ID

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
