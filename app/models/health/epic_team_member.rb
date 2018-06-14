module Health
  class EpicTeamMember < Base
    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_team_members

    scope :unprocessed, -> do
      where(processed: nil).
      where.not(email: nil)
    end

    scope :processed, -> do
      where.no(processed: nil)
    end

    self.source_key = :CARETEAM_ID
    
    def self.csv_map(version: nil)
      {
        PAT_ID: :patient_id,
        CARETEAM_ID: :id_in_source,
        name: :name,
        PCP_TYPE: :pcp_type,
        RELATIONSHIP: :relationship,
        email: :email,
        phone: :phone,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end

  end
end