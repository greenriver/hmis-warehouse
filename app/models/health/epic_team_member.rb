module Health
  class EpicTeamMember < Base
    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_team_members

    scope :unprocessed, -> do
      where(processed: nil)
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

    # create team members for any matching unprocessed team members
    # don't add them to pilot patients
    def self.process!
      Health::Patient.bh_cp.joins(:epic_team_members).merge(Health::EpicTeamMember.unprocessed).
        distinct.each do |patient|
          patient.import_epic_team_members
      end
    end

  end
end