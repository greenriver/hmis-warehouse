module Health
  class Patient < Base

    has_many :appointments, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :medications, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :problems, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :visits, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient

    has_one :team
    has_many :team_members, class_name: Health::Team::Member.name, through: :team

    has_one :careplan
    has_many :goals, class_name: Health::Goal::Base.name, through: :careplan

    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name

    scope :unprocessed, -> { where client_id: nil}
    scope :consent_revoked, -> {where.not(consent_revoked: nil)}
    scope :consented, -> {where(consent_revoked: nil)}

    self.source_key = :PAT_ID

    def self.accessible_by_user user
      # health admins can see all, including consent revoked
      if user.can_administer_health?
        all
      # everyone else can only see consented patients
      elsif user.present? && (user.can_edit_client_health? || user.can_view_client_health?)
        consented
      else
        none
      end
    end
    
    def accessible_by_user user
      return false unless user.present?
      return true if user.can_administer_health?
      return true if consented? && (user.can_edit_client_health? || user.can_view_client_health?)
      return false
    end

    def consented?
      consent_revoked.blank?
    end

    def consent_revoked?
      consent_revoked.present?
    end

    def self.revoke_consent
      update_all(consent_revoked: Time.now)
    end

    def self.restore_consent
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
        ssn: :ssn,
        row_created: :created_at,
        row_updated: :updated_at,
      }
    end

    def name
      full_name = "#{first_name} #{middle_name} #{last_name}"
      full_name << "(#{aliases})" if aliases.present?
      return full_name
    end
  end
end
