###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class EpicPatient < EpicBase
    acts_as_paranoid

    phi_patient :medicaid_id
    phi_attr :id_in_source, Phi::MedicalRecordNumber
    phi_attr :first_name, Phi::Name, 'First name of patient'
    phi_attr :middle_name, Phi::Name, 'Middle name of patient'
    phi_attr :last_name, Phi::Name, 'Last name of patient'
    phi_attr :aliases, Phi::Name, 'Aliases of patient'
    phi_attr :birthdate, Phi::Date, 'Date of birth of patient'
    phi_attr :allergy_list, Phi::NeedsReview, "List of patient's allergy"
    phi_attr :primary_care_physician, Phi::SmallPopulation, 'Name of primary care physician'
    phi_attr :transgender, Phi::SmallPopulation, 'Identifying gender of patient'
    phi_attr :race, Phi::SmallPopulation, 'Race of patient'
    phi_attr :ethnicity, Phi::SmallPopulation, 'Ethnicity of patient'
    phi_attr :veteran_status, Phi::SmallPopulation, 'Veteran status of patient'
    phi_attr :ssn, Phi::Ssn, 'Social security number of patient'
    phi_attr :gender, Phi::SmallPopulation, 'Gender of patient'
    phi_attr :consent_revoked, Phi::Date, 'Date of revocation of consent'
    phi_attr :medicaid_id, Phi::HealthPlan, 'Medicaid plan ID'
    phi_attr :housing_status_timestamp, Phi::Date, 'Timestamp of current housing status update'
    phi_attr :death_date, Phi::Date, 'Date of death'
    phi_attr :data_source_id, Phi::SmallPopulation, 'Source of data (may identify provider)'

    has_one :patient, primary_key: :medicaid_id, foreign_key: :medicaid_id
    has_many :appointments, **epic_assoc(model: :appointment, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :epic_patient
    has_many :medications, **epic_assoc(model: :medication, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :epic_patient
    has_many :problems, **epic_assoc(model: :problem, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :patient
    has_many :visits, **epic_assoc(model: :visit, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :patient
    has_many :epic_goals, **epic_assoc(model: :epic_goal, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :patient
    has_many :epic_case_notes, **epic_assoc(model: :epic_case_note, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :patient
    has_many :epic_case_note_qualifying_activities, **epic_assoc(model: :epic_case_note_qualifying_activity, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :patient
    has_many :epic_team_members, **epic_assoc(model: :epic_team_member, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :patient
    has_many :epic_qualifying_activities, **epic_assoc(model: :epic_qualifying_activity, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :epic_patient
    has_many :epic_careplans, **epic_assoc(model: :epic_careplan, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :epic_patient
    has_many :epic_chas, **epic_assoc(model: :epic_cha, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :epic_patient
    has_many :epic_ssms, **epic_assoc(model: :epic_ssm, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :epic_patient
    has_many :epic_housing_statuses, **epic_assoc(model: :epic_housing_status, primary_key: :id_in_source, foreign_key: :patient_id), inverse_of: :epic_patient

    scope :pilot, -> { where pilot: true }
    scope :hpc, -> { where pilot: false }
    scope :bh_cp, -> { where pilot: false }

    scope :consent_revoked, -> { where.not(consent_revoked: nil) }
    scope :consented, -> { where(consent_revoked: nil) }

    self.source_key = :PAT_ID

    def available_team_members
      team_members.map { |t| [t.full_name, t.id] }
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

    def self.csv_map(_version: nil)
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

      full_name
    end
  end
end
