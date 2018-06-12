module Health
  class Patient < Base

    has_many :appointments, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :medications, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :problems, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :visits, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient
    has_many :epic_goals, primary_key: :id_in_source, foreign_key: :patient_id, inverse_of: :patient

    has_many :ed_nyu_severities, class_name: Health::Claims::EdNyuSeverity.name, primary_key: :medicaid_id, foreign_key: :medicaid_id

    has_many :teams, through: :careplans
    has_many :team_members, class_name: Health::Team::Member.name, through: :team

    has_many :goals, class_name: Health::Goal::Base.name, through: :careplans

    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name

    has_one :claims_roster, class_name: Health::Claims::Roster.name, primary_key: :medicaid_id, foreign_key: :medicaid_id
    has_many :amount_paids, class_name: Health::Claims::AmountPaid.name, primary_key: :medicaid_id, foreign_key: :medicaid_id
    has_many :self_sufficiency_matrix_forms
    has_many :hmis_ssms, -> do
      merge(GrdaWarehouse::HmisForm.self_sufficiency)
    end, class_name: GrdaWarehouse::HmisForm.name, through: :client, source: :source_hmis_forms
    has_many :sdh_case_management_notes
    has_many :participation_forms
    has_many :release_forms
    has_many :comprehensive_health_assessments
    has_many :careplans

    has_many :services
    has_many :equipments

    has_one :patient_referral, required: false
    has_one :health_agency, through: :patient_referral, source: :assigned_agency
    has_one :care_coordinator, class_name: User.name
    has_many :qualifying_activities

    scope :pilot, -> { where pilot: true }
    scope :hpc, -> { where pilot: false }

    scope :unprocessed, -> { where client_id: nil}
    scope :consent_revoked, -> {where.not(consent_revoked: nil)}
    scope :consented, -> {where(consent_revoked: nil)}

    scope :full_text_search, -> (text) do
      text_search(text, patient_scope: current_scope)
    end

    # at least one of the following is true
    # No SSM
    # No Participation Form
    # No Release Form
    # No CHA
    scope :not_engaged, -> do
      # This lives in the warehouse DB and must be materialized
      hmis_ssm_client_ids = GrdaWarehouse::Hud::Client.joins(:source_hmis_forms).merge(GrdaWarehouse::HmisForm.self_sufficiency).distinct.pluck(:client_id)

      ssm_patient_id_scope = Health::SelfSufficiencyMatrixForm.completed.distinct.select(:patient_id)
      participation_form_patient_id_scope = Health::ParticipationForm.reviewed.distinct.select(:patient_id)
      release_form_patient_id_scope = Health::ReleaseForm.reviewed.distinct.select(:patient_id)
      cha_patient_id_scope = Health::ComprehensiveHealthAssessment.reviewed.distinct.select(:patient_id)
      where(
        arel_table[:client_id].not_in(hmis_ssm_client_ids).
        and(
          arel_table[:id].not_in(Arel.sql ssm_patient_id_scope.to_sql)
        ).
        or(
          arel_table[:id].not_in(Arel.sql participation_form_patient_id_scope.to_sql)
        ).
        or(
          arel_table[:id].not_in(Arel.sql release_form_patient_id_scope.to_sql)
        ).
        or(
          arel_table[:id].not_in(Arel.sql cha_patient_id_scope.to_sql)
        )
      )
    end

    # all must be true
    # Has SSM
    # Has Participation Form
    # Has Release Form
    # Has CHA
    scope :engaged, -> do
      # This lives in the warehouse DB and must be materialized
      hmis_ssm_client_ids = GrdaWarehouse::Hud::Client.joins(:source_hmis_forms).merge(GrdaWarehouse::HmisForm.self_sufficiency).distinct.pluck(:id)

      ssm_patient_id_scope = Health::SelfSufficiencyMatrixForm.completed.distinct.select(:patient_id)
      participation_form_patient_id_scope = Health::ParticipationForm.reviewed.distinct.select(:patient_id)
      release_form_patient_id_scope = Health::ReleaseForm.reviewed.distinct.select(:patient_id)
      cha_patient_id_scope = Health::ComprehensiveHealthAssessment.reviewed.distinct.select(:patient_id)

      where(
        arel_table[:client_id].in(hmis_ssm_client_ids).
        or(
          arel_table[:id].in(Arel.sql ssm_patient_id_scope.to_sql)
        ).
        and(
          arel_table[:id].in(Arel.sql participation_form_patient_id_scope.to_sql)
        ).
        and(
          arel_table[:id].in(Arel.sql release_form_patient_id_scope.to_sql)
        ).
        and(
          arel_table[:id].in(Arel.sql cha_patient_id_scope.to_sql)
        )
      )
    end

    scope :engagement_required_by, -> (date) do
      not_engaged.where(arel_table[:engagement_date].lteq(date))
    end

    scope :engagement_ending, -> do
      engagement_required_by(1.months.from_now)
    end

    # patients with no qualifying activities in the past month
    scope :no_recent_qualifying_activities, -> do
      where.not(
        id: Health::QualifyingActivity.in_range(1.months.ago..Date.today).
          distinct.select(:patient_id)
      )
    end

    delegate :effective_date, to: :patient_referral

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

    def days_to_engage 
      return 0 unless engagement_date.present?
      (engagement_date - Date.today).to_i.clamp(0, 180)
    end

    def chas
      comprehensive_health_assessments
    end
    
    def accessible_by_user user
      return false unless user.present?
      return true if user.can_administer_health?
      return true if consented? && (user.can_edit_client_health? || user.can_view_client_health?)
      return false
    end

    def pilot_patient?
      pilot == true
    end

    def hpc_patient? # also referred to as BH CP
      ! pilot_patient?
    end

    def engaged?
      self.class.engaged.where(id: id).exists?
      # ssms? && participation_forms.reviewed.exists? && release_forms.reviewed.exists? && comprehensive_health_assessments.reviewed.exists?
    end

    def ssms?
      self_sufficiency_matrix_forms.completed.exists? || hmis_ssms.exists?
    end

    def ssms
      @ssms ||= (hmis_ssms.order(collected_at: :desc).to_a + self_sufficiency_matrix_forms.order(completed_at: :desc).to_a).sort_by do |f|
        if f.is_a? Health::SelfSufficiencyMatrixForm
          f.completed_at
        elsif f.is_a? GrdaWarehouse::HmisForm
          f.collected_at
        end
      end
    end

    def qualified_activities_since date: 1.months.ago
      qualifying_activities.in_range(date..Date.tomorrow)
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
        ssn: :ssn,
        row_created: :created_at,
        row_updated: :updated_at,
        medicaid_id: :medicaid_id,
        housing_status: :housing_status,
        housing_status_timestamp: :housing_status_timestamp,
      }
    end

    def name
      full_name = "#{first_name} #{middle_name} #{last_name}"
      full_name << " (#{aliases})" if aliases.present?
      return full_name
    end

    def available_care_coordinators
      user_ids = Health::AgencyUser.where(agency_id: health_agency.id).pluck(:user_id)
      User.where(id: user_ids)
    end

    def housing_stati
      client.case_management_notes.map do |form|
        first_section = form.answers[:sections].first
        if first_section.present?
          answer = form.answers[:sections].first[:questions].select do |question|
            question[:question] == "A-6. Where did you sleep last night?"
          end.first
          status = client.class.health_housing_bucket(answer[:answer])
          OpenStruct.new({
            date: form.collected_at.to_date, 
            postitive_outcome: client.class.health_housing_positive_outcome?(answer[:answer]),
            outcome: status,
            detail: answer[:answer],
          })
        end
      end.select{|row| row.outcome.present?}.
        index_by(&:date).values.
        sort_by(&:date).reverse
    end

    def current_housing_status
      # return nil unless housing_stati.any?
      # most_recent = housing_stati.first
      # last_status = housing_stati&.second
      # if last_status.present? # FIXME
      #   most_recent.positive_change
      # end
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

    def self.ransackable_scopes(auth_object = nil)
      [:full_text_search]
    end

    def self.text_search(text, patient_scope:)
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
      patient_scope.where(where)
    end
  end
end
