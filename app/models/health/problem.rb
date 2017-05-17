module Health
  class Problem < Base

    belongs_to :patient

    self.source_key = :PL_ID
    
    def self.csv_map(version: nil)
      {
        PAT_ID: :patient_id,
        PL_ID: :id_in_source,
        name: :name,
        comment: :comment,
        icd10_list: :icd10_list,
        last_assessed: :last_assessed,
        onset_date: :onset_date,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end
  end
end
