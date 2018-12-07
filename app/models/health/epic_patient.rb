# Risk: Describes a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EpicPatient < EpicBase
    acts_as_paranoid

    phi_patient :medicaid_id
    phi_attr :id_in_source, Phi::MedicalRecordNumber
    phi_attr :first_name, Phi::Name
    phi_attr :middle_name, Phi::Name
    phi_attr :last_name, Phi::Name
    phi_attr :aliases, Phi::Name
    phi_attr :birthdate, Phi::Date
    phi_attr :allergy_list, Phi::NeedsReview
    phi_attr :primary_care_physician, Phi::SmallPopulation
    phi_attr :transgender, Phi::SmallPopulation
    phi_attr :race, Phi::SmallPopulation
    phi_attr :ethnicity, Phi::SmallPopulation
    phi_attr :veteran_status, Phi::SmallPopulation
    phi_attr :ssn, Phi::Ssn
    phi_attr :gender, Phi::SmallPopulation
    phi_attr :consent_revoked, Phi::Date
    phi_attr :medicaid_id, Phi::HealthPlan
    phi_attr :housing_status_timestamp, Phi::Date
    phi_attr :death_date, Phi::Date

    has_one :patient, primary_key: :medicaid_id, foreign_key: :medicaid_id
    has_many :appointments, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :medications, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :problems, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :visits, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :epic_goals, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :epic_case_notes, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :epic_case_note_qualifying_activities, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :epic_team_members, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :epic_qualifying_activities, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_patient
    has_many :epic_careplans, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_patient
    has_many :epic_chas, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_patient
    has_many :epic_ssms, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :epic_patient

    scope :pilot, -> { where pilot: true }
    scope :hpc, -> { where pilot: false }
    scope :bh_cp, -> { where pilot: false }

    scope :consent_revoked, -> {where.not(consent_revoked: nil)}
    scope :consented, -> {where(consent_revoked: nil)}

    self.source_key = :PAT_ID

    def available_team_members
      team_members.map{|t| [t.full_name, t.id]}
    end

    def pilot_patient?
      pilot == true
    end

    def hpc_patient? # also referred to as BH CP
      bh_cp_patient?
    end

    def bh_cp_patient? # also referred to as BH CP
      ! pilot_patient?
    end

    def consented? # Pilot
      consent_revoked.blank?
    end

    def consent_revoked? # Pilot
      consent_revoked.present?
    end

    def self.revoke_consent # Pilot
      update_all(consent_revoked: Time.now)
    end

    def self.restore_consent # Pilot
      update_all(consent_revoked: nil)
    end

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
        death_date: :death_date,
        ssn: :ssn,
        row_created: :created_at,
        row_updated: :updated_at,
        medicaid_id: :medicaid_id,
        housing_status: :housing_status,
        housing_status_timestamp: :housing_status_timestamp,
        program: :pilot,
      }
    end

    def self.clean_value key, value
      value = case key
      when :pilot
        value.include?('SDH')
      else
        value.presence
      end
      super(key, value)
    end

    def name
      full_name = "#{first_name} #{middle_name} #{last_name}"
      full_name << " (#{aliases})" if aliases.present?
      return full_name
    end
  end
end
