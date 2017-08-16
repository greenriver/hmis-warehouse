module GrdaWarehouse
  class Vispdat < GrdaWarehouseBase
    ####################
    # Constants
    ####################
    US_PHONE_NUMBERS = /\A(\+1)?\(?(\d{3})\)?\s*-?\s*(\d{3})\s*-?\s*(\d{4})\s*-?\s*\z/

    ####################
    # enums
    ####################
    enum language_answer: [:language_english, :language_spanish, :language_french]
    enum sleep_answer: [:sleep_shelters, :sleep_transitional_housing, :sleep_safe_haven, :sleep_outdoors, :sleep_other, :sleep_refused]

    %w(attacked threatened legal tricked risky owe_money get_money activities basic_needs abusive leave chronic hiv disability avoid_help pregnant eviction drinking mental head learning brain medication sell trauma picture).each do |field|
      enum "#{field}_answer".to_sym => { "#{field}_answer_yes".to_sym => 1, "#{field}_answer_no".to_sym => 0, "#{field}_answer_refused".to_sym => 2 }
    end

    enum when_answer: [:morning, :afternoon, :evening, :night]

    ####################
    # Associations
    ####################
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'

    ####################
    # Behaviors
    ####################
    has_paper_trail

    ####################
    # Validations
    ####################
    validates :first_name, presence: true, length: { in: 2..30 }
    validates :nickname, length: { in: 2..30 }, allow_blank: true
    validates :last_name, presence: true, length: { in: 2..30 }
    validates :dob, presence: true
    validate :dob_is_reasonable
    validates :language_answer, inclusion: { in: language_answers.keys }, allow_blank: true

    validates :sleep_answer, inclusion: { in: sleep_answers.keys }, allow_blank: true
    validates :sleep_answer_other, length: { in: 2..100 }, presence: true, if: -> { sleep_other? }
    validates :years_homeless, numericality: { only_integer: true }, inclusion: { in: 0..30, message: 'should be between 0 and 30' }, unless: -> { years_homeless_refused? }
    validates :episodes_homeless, numericality: { onlyt_integer: true }, inclusion: { in: 0..36, message: 'should be between 0 and 36'}, unless: -> { episodes_homeless_refused? }

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
    validates :phone, format: { with: US_PHONE_NUMBERS }
    validates_email_format_of :email

    # Require the refused checkbox to be checked if no answer given
    # Require an answer if the refused checkbox not checked.
    %w(
      years_homeless
      episodes_homeless
      emergency_healthcare
      ambulance
      inpatient
      crisis_service
      talked_to_police
      jail
    ).each do |field|
      # if both blank, indicate that refused must be checked
      validates [field, '_refused'].join.to_sym, presence: { message: 'should be checked if refusing to answering' }, if: -> { send(field.to_sym).blank? }

      # if both blank, indicate a value is needed
      validates field.to_sym, presence: { message: 'please enter a value or mark refused' }, if: -> { send([field, '_refused?'].join.to_sym).blank? }

      # if refused checked and answer given
      validates field.to_sym, absence: { message: 'cannot have an entry if refusing to answer' }, if: -> { send([field, '_refused?'].join.to_sym) }
    end

    ####################
    # Callbacks
    ####################
    before_save :calculate_score

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

    def self.options_for enum
      ['Yes', 'No', 'Refused'].zip self.send(enum).keys
    end

    def full_name
      [first_name, last_name].join ' '
    end

    def age
      return unless dob.present?
      ((Date.today - dob).to_i / 365.25).to_i
    end

    def answer_for enum
      return '-' if send(enum).blank?
      send(enum).titleize.split.last
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
      return 0 unless dob.present?
      dob > 60.years.ago ? 0 : 1
    end
    def sleep_score
      (sleep_outdoors? || sleep_other? || sleep_refused?) ? 1 : 0
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
      activities_answer_yes? ? 0 : 1
    end
    def self_care_score
      basic_needs_answer_yes? ? 0 : 1
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

    private

    def dob_is_reasonable
      unless dob.present? && dob.between?(100.years.ago, 1.day.ago)
        errors.add :dob, "date of birth is missing / too old / too young"
      end
    end

  end
end
