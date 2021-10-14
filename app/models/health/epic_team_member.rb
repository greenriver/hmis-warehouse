###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EpicTeamMember < EpicBase
    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier, "ID of team member"
    phi_attr :id_in_source, Phi::OtherIdentifier
    phi_attr :name, Phi::SmallPopulation, "Name of team member"
    # phi_attr :pcp_type
    # phi_attr :relationship
    phi_attr :email, Phi::SmallPopulation, "Email of team member"
    phi_attr :phone, Phi::SmallPopulation, "Phone number of team member"
    # phi_attr :processed

    belongs_to :patient, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_team_members, optional: true

    scope :unprocessed, -> do
      where(processed: nil)
    end

    scope :processed, -> do
      where.not(processed: nil)
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

    def previously_processed_ids
      @previously_processed_ids ||= self.class.processed.pluck(:id_in_source, :data_source_id, :processed).
        map{|id, ds, processed| [[id, ds], processed]}.to_h
    end

    def previously_processed id_in_source:, data_source_id:
      previously_processed_ids[[id_in_source, data_source_id]]
    end

    def clean_row row:, data_source_id:
      row << {'processed' => previously_processed(id_in_source: row[self.class.source_key.to_s], data_source_id: data_source_id.to_i)}
      row
    end

  end
end
