module Health
  class Patient < Base

    has_many :appointments
    has_many :medications
    has_many :problems
    has_many :visits

    scope :unprocessed, -> { where client_id: nil}
    
    self.source_key = :PAT_ID
    
    def self.csv_map(version: nil)
      {
        PAT_ID: :id_in_source,
        sex: :gender,
        first_name: :first_name,
        middle_name: :middle_name,
        last_name: :last_name,
        alias_list: :aliases,
        birthdate: :birthdate,
        allergy_list: :allergy_list,
        pcp: :primary_care_physician,
        tg: :transgender,
        race: :race,
        ethnicity: :ethnicity,
        vet_status: :veteran_status,
        ssn: :ssn,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end

  end
end
