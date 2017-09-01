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
        medicaid_id: :medicaid_id,
      }
    end

    def name
      full_name = "#{first_name} #{middle_name} #{last_name}"
      full_name << " (#{aliases})" if aliases.present?
      return full_name
    end

    def self.sort_options
      [
        {title: 'Patient Last name A-Z', column: :patient_last_name, direction: 'asc'},
        {title: 'Patient Last name Z-A', column: :patient_last_name, direction: 'desc'},
        {title: 'Patient First name A-Z', column: :patient_first_name, direction: 'asc'},
        {title: 'Patient First name Z-A', column: :patient_first_name, direction: 'desc'},
      ]
    end

    def self.column_from_sort(column: nil, direction: nil)
      { 
        [:patient_last_name, :asc] => arel_table[:last_name].asc,
        [:patient_last_name, :desc] => arel_table[:last_name].desc,
        [:patient_first_name, :asc] => arel_table[:first_name].asc,
        [:patient_first_name, :desc] => arel_table[:first_name].desc,
      }[[column.to_sym, direction.to_sym]] || default  
    end

    def self.default_sort_column
      :patient_last_name
    end

    def self.default_sort_direction
      :asc
    end

    def self.text_search(text)
      return none unless text.present?
      text.strip!
      patient_t = arel_table

      # Explicitly search for only last, first if there's a comma in the search
      if text.include?(',')
        last, first = text.split(',').map(&:strip)
        where = patient_t[:first_name].lower.matches("#{first.downcase}%")
          .and(patient_t[:last_name].lower.matches("#{last.downcase}%"))
      # Explicity search for "first last"
      elsif text.include?(' ')
        first, last = text.split(' ').map(&:strip)
        where = patient_t[:first_name].lower.matches("#{first.downcase}%")
          .and(patient_t[:last_name].lower.matches("#{last.downcase}%"))
      else
        query = "%#{text.downcase}%"
        
        where = patient_t[:last_name].lower.matches(query).
          or(patient_t[:first_name].lower.matches(query)).
          or(patient_t[:id_in_source].lower.matches(query))
      end
      where(where)
    end
  end
end
