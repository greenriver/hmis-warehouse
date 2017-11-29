module GrdaWarehouse::Vispdat
  class Base < GrdaWarehouseBase
    self.table_name = :vispdats
    ####################
    # Constants
    ####################
    US_PHONE_NUMBERS = /\A(\+1)?\(?(\d{3})\)?\s*-?\s*(\d{3})\s*-?\s*(\d{4})\s*-?\s*\z/

    ####################
    # enums
    ####################
    enum language_answer: [
      :language_english,
      :language_spanish,
      :language_french,
      :language_chinese,
      :language_hindi,
      :language_arabic,
      :language_portuguese,
      :language_bengali,
      :language_russian,
      :language_japanese,
      :language_punjabi,
      :language_german
    ]
    enum sleep_answer: {
      sleep_shelters: 0,
      sleep_transitional_housing: 1,
      sleep_safe_haven: 2,
      sleep_outdoors: 3,
      sleep_other: 4,
      sleep_refused: 5,
      sleep_couch_surfing: 6
    }

    enum homeless_period: [:days, :weeks, :months, :years]

    %w(attacked threatened legal tricked risky owe_money get_money activities basic_needs abusive leave chronic hiv disability avoid_help pregnant eviction drinking mental head learning brain medication sell trauma picture).each do |field|
      enum "#{field}_answer".to_sym => { "#{field}_answer_yes".to_sym => 1, "#{field}_answer_no".to_sym => 0, "#{field}_answer_refused".to_sym => 2 }
    end

    enum when_answer: [:morning, :afternoon, :evening, :night]

    ####################
    # Associations
    ####################
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    has_many :files, class_name: 'GrdaWarehouse::ClientFile', foreign_key: 'vispdat_id'

    ####################
    # Behaviors
    ####################
    has_paper_trail

    ####################
    # Validations
    ####################
    validates :nickname, length: { in: 2..30 }, allow_blank: true
    validates :language_answer, inclusion: { in: language_answers.keys }, allow_blank: true

    validates :sleep_answer, inclusion: { in: sleep_answers.keys }, allow_blank: true
    validates :sleep_answer_other, length: { in: 2..100 }, presence: true, if: -> { sleep_other? }
    validates :homeless, numericality: { only_integer: true }, unless: -> { homeless_refused? }
    validates :homeless_period, presence: true, if: -> { homeless.present? }
    validates :episodes_homeless, numericality: { only_integer: true }, inclusion: { in: 0..36, message: 'should be between 0 and 36'}, unless: -> { episodes_homeless_refused? }

    with_options numericality: { only_integer: true }, inclusion: { in: 0..25, message: 'should be between 0 and 25' } do |number_of_times|
      number_of_times.validates :emergency_healthcare, unless: -> { emergency_healthcare_refused? }
      number_of_times.validates :ambulance, unless: -> { ambulance_refused? }
      number_of_times.validates :inpatient, unless: -> { inpatient_refused? }
      number_of_times.validates :crisis_service, unless: -> { crisis_service_refused? }
      number_of_times.validates :talked_to_police, unless: -> { talked_to_police_refused? }
      number_of_times.validates :jail, unless: -> { jail_refused? }
    end

    validates :find_location, length: { in: 0..100 }
    validates :find_time, length: { in: 0..10 }
    validates :when_answer, inclusion: { in: when_answers.keys }, allow_blank: true
    validates :phone, format: { with: US_PHONE_NUMBERS }, allow_blank: true
    validates_email_format_of :email, allow_blank: true

    # Require the refused checkbox to be checked if no answer given
    # Require an answer if the refused checkbox not checked.
    %w(
      homeless
      episodes_homeless
      emergency_healthcare
      ambulance
      inpatient
      crisis_service
      talked_to_police
      jail
    ).each do |field|
      # if both blank, indicate that refused must be checked
      validates [field, '_refused'].join.to_sym, presence: { message: 'should be checked if refusing to answer' }, if: -> { send(field.to_sym).blank? }

      # if both blank, indicate a value is needed
      validates field.to_sym, presence: { message: 'please enter a value or mark refused' }, if: -> { send([field, '_refused?'].join.to_sym).blank? }

      # if refused checked and answer given
      validates field.to_sym, absence: { message: 'cannot have an entry if refusing to answer' }, if: -> { send([field, '_refused?'].join.to_sym) }
    end

    ####################
    # Scopes
    ####################

    scope :in_progress, -> { where(submitted_at: nil) }
    scope :completed, -> { where.not(submitted_at: nil) }
    scope :active, -> { where(active: true) }
    scope :scores, -> { order(submitted_at: :desc).select(:score, :priority_score) }
    scope :high_vulnerability, -> { 
      where(priority_score: 731..Float::INFINITY)
    }
    scope :medium_vulnerability, -> {
      where(priority_score: 365..730)
    }
    scope :low_vulnerability, -> {
      where(priority_score: 0..364)
    }
    scope :visible_by?, -> (user) do
      if user.can_view_vspdat? || user.can_edit_vspdat?
        all
      elsif user.can_submit_vspdat?
        in_progress
      else
        none
      end
    end

    ####################
    # Callbacks
    ####################
    before_save :calculate_score, :calculate_priority_score, :set_client_housing_release_status
    after_update :notify_users

    ####################
    # Access
    ####################
    def self.any_visible_by?(user)
      user.can_view_vspdat? || user.can_edit_vspdat? || user.can_submit_vspdat?
    end

    def self.any_modifiable_by(user)
      user.can_edit_vspdat? || user.can_submit_vspdat?
    end

    def show_as_readonly?
      ! changed? && (migrated? || completed?) 
    end

    def visible_by?(user)
      self.class.visible_by?(user).where(id: id).exists?
    end

    def set_client_housing_release_status
      if housing_release_confirmed_changed?
        status = housing_release_confirmed? ? GrdaWarehouse::Hud::Client.full_release_string : ''
        client.update_column :housing_release_status, status
      end
    end

    def notify_users
      return if changes.empty?
      notify_vispdat_completed
    end

    def notify_vispdat_completed
      before, after = changes[:submitted_at]
      if before.nil? && after.present?
        NotifyUser.vispdat_completed( id ).deliver_later
      end
    end

    def youth?
      false
    end

    def individual?
      false
    end

    def family?
      false
    end

    def disassociate_files
      # need unscoped to catch deleted files
      files.unscoped.where(vispdat_id: id).update_all(vispdat_id: nil)
    end

    def calculate_score
      self.score = pre_survey_score +
      history_score +
      risk_score +
      social_score +
      wellness_score
    end
    def calculate_score!
      calculate_score
      save
    end

    def calculate_priority_score
      homeless = days_homeless
      begin
        self.priority_score = if score >= 8 && homeless > 730
          score + 730
        elsif score >= 8 && homeless >= 365
          score + 365
        elsif score >= 0
          score
        else
          0
        end
      rescue
        0
      end
    end

    def calculate_recommendation
      self.recommendation = case score
      when 0..3
        "No Housing Intervention"
      when 4..7
        "An Assessment for Rapid Re-Housing"
      when 8..Float::INFINITY
        "An Assessment for Permanent Supportive Housing/Housing First"
      else
        "Invalid Score"
      end
    end
    def calculate_recommendation!
      calculate_recommendation
      save
    end

    def score_class
      case score
      when 0..3
        'success'
      when 4..7
        'warning'
      when 8..Float::INFINITY
        'danger'
      else
        'default'
      end
    end

    def version
      2
    end

    def self.language_options
      language_answers.map do |k,_|
        [k.split('_').last.capitalize, k]
      end
    end

    def self.sleep_options
      sleep_answers.map do |k,_|
        [k.split('_').drop(1).join(' ').titleize, k]
      end
    end

    def self.when_options
      when_answers.map do |k,_|
        [k.capitalize, k]
      end
    end

    def self.homeless_period_options
      homeless_periods.map do |k,_|
        [k.capitalize, k]
      end
    end

    def self.options_for enum
      ['Yes', 'No', 'Refused/Unsure'].zip self.send(enum).keys
    end

    def full_name
      client.full_name
    end

    def answer_for enum
      return '-' if send(enum).blank?
      send(enum).titleize.split.last
    end

    def completed?
      submitted_at.present?
    end

    def in_progress?
      !completed
    end

    def expired?
      return true unless release_signed_on
      release_signed_on && release_signed_on < 1.year.ago
    end

    ####################
    # Section Scoring Formulas
    ####################
    def pre_survey_score
      dob_score
    end
    def history_score
      sleep_score +
      homeless_score
    end
    def risk_score
      emergency_service_score +
      risk_of_harm_score +
      legal_issues_score +
      risk_of_exploitation_score
    end
    def social_score
      money_management_score +
      meaningful_activity_score +
      self_care_score +
      social_relationship_score
    end
    def wellness_score
      physical_health_score +
      substance_abuse_score +
      mental_health_score +
      tri_morbidity_score +
      medication_score +
      abuse_and_trauma_score
    end

    ####################
    # Question Scoring Formulas
    ####################
    def dob_score
      age = client.age
      return 0 unless age.present?
      age >= 60 ? 1 : 0
    end
    def sleep_score
      (sleep_outdoors? || sleep_couch_surfing? || sleep_other? || sleep_refused?) ? 1 : 0
    end
    def homeless_score
      (years_homeless.to_i > 0 || episodes_homeless.to_i > 3) ? 1 : 0
    end
    def emergency_service_score
      (emergency_healthcare.to_i + ambulance.to_i + inpatient.to_i + crisis_service.to_i + talked_to_police.to_i + jail.to_i) > 3 ? 1 : 0
    end
    def risk_of_harm_score
      (attacked_answer_yes? || threatened_answer_yes?) ? 1 : 0
    end
    def legal_issues_score
      legal_answer_yes? ? 1 : 0
    end
    def risk_of_exploitation_score
      (tricked_answer_yes? || risky_answer_yes?) ? 1 : 0
    end
    def money_management_score
      (owe_money_answer_yes? || get_money_answer_no?) ? 1 : 0
    end
    def meaningful_activity_score
      activities_answer_no? ? 1 : 0
    end
    def self_care_score
      basic_needs_answer_no? ? 1 : 0
    end
    def social_relationship_score
      abusive_answer_yes? ? 1 : 0
    end
    def physical_health_score
      (leave_answer_yes? || chronic_answer_yes? || hiv_answer_yes? || disability_answer_yes? || avoid_help_answer_yes? || pregnant_answer_yes?) ? 1 : 0
    end
    def substance_abuse_score
      (eviction_answer_yes? || drinking_answer_yes?) ? 1 : 0
    end
    def mental_health_score
      (mental_answer_yes? || head_answer_yes? || learning_answer_yes? || brain_answer_yes?) ? 1 : 0
    end
    def tri_morbidity_score
      (physical_health_score==1 && substance_abuse_score==1 && mental_health_score==1) ? 1 : 0
    end
    def medication_score
      (medication_answer_yes? || sell_answer_yes?) ? 1 : 0
    end
    def abuse_and_trauma_score
      trauma_answer_yes? ? 1 : 0
    end

    def years_homeless
      case homeless_period
      when 'days'
        homeless.to_i/365
      when 'weeks'
        homeless.to_i/52
      when 'months'
        homeless.to_i/12
      when 'years'
        homeless.to_i
      else
        0
      end
    end

    def days_homeless
      case homeless_period
      when 'days'
        homeless.to_i
      when 'weeks'
        homeless.to_i * 7
      when 'months'
        homeless.to_i * 30
      when 'years'
        homeless.to_i * 365
      else
        0
      end
    end

    def self.allowed_parameters
      [
        :nickname,
        :language_answer,
        :release_signed_on,
        :housing_release_confirmed,
        :hiv_release,
        :drug_release,
        :sleep_answer,
        :sleep_answer_other,
        :homeless,
        :homeless_refused,
        :homeless_period,
        :episodes_homeless,
        :episodes_homeless_refused,
        :emergency_healthcare,
        :emergency_healthcare_refused,
        :ambulance,
        :ambulance_refused,
        :inpatient,
        :inpatient_refused,
        :crisis_service,
        :crisis_service_refused,
        :talked_to_police,
        :talked_to_police_refused,
        :jail,
        :jail_refused,
        :attacked_answer,
        :threatened_answer,
        :legal_answer,
        :tricked_answer,
        :risky_answer,
        :owe_money_answer,
        :get_money_answer,
        :activities_answer,
        :basic_needs_answer,
        :abusive_answer,
        :leave_answer,
        :chronic_answer,
        :hiv_answer,
        :disability_answer,
        :avoid_help_answer,
        :pregnant_answer,
        :eviction_answer,
        :drinking_answer,
        :mental_answer,
        :head_answer,
        :learning_answer,
        :brain_answer,
        :medication_answer,
        :sell_answer,
        :trauma_answer,
        :find_location,
        :find_time,
        :when_answer,
        :phone,
        :email,
        :picture_answer
      ]
    end

  end
end
