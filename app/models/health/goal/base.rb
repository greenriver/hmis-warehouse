# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Goal::Base < HealthBase
    self.table_name = 'health_goals'
    has_paper_trail class_name: Health::HealthVersion.name
    acts_as_paranoid

    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier
    phi_attr :user_id, Phi::SmallPopulation
    # phi_attr :type,
    # phi_attr :number,
    phi_attr :name, Phi::FreeText
    phi_attr :associated_dx, Phi::FreeText
    phi_attr :barriers, Phi::FreeText
    phi_attr :provider_plan, Phi::FreeText
    phi_attr :case_manager_plan, Phi::FreeText
    phi_attr :rn_plan, Phi::FreeText
    phi_attr :bh_plan, Phi::FreeText
    phi_attr :other_plan, Phi::FreeText
    # phi_attr :confidence,
    phi_attr :az_housing, Phi::FreeText
    phi_attr :az_income, Phi::FreeText
    phi_attr :az_non_cash_benefits, Phi::FreeText
    phi_attr :az_disabilities, Phi::FreeText
    phi_attr :az_food, Phi::FreeText
    phi_attr :az_employment, Phi::FreeText
    phi_attr :az_training, Phi::FreeText
    phi_attr :az_transportation, Phi::FreeText
    phi_attr :az_life_skills, Phi::FreeText
    phi_attr :az_health_care_coverage, Phi::FreeText
    phi_attr :az_physical_health, Phi::FreeText
    phi_attr :az_mental_health, Phi::FreeText
    phi_attr :az_substance_use, Phi::FreeText
    phi_attr :az_criminal_justice, Phi::FreeText
    phi_attr :az_legal, Phi::FreeText
    phi_attr :az_safety, Phi::FreeText
    phi_attr :az_risk, Phi::FreeText
    phi_attr :az_family, Phi::FreeText
    phi_attr :az_community, Phi::FreeText
    phi_attr :az_time_management, Phi::FreeText
    phi_attr :goal_details, Phi::FreeText
    phi_attr :problem, Phi::FreeText
    phi_attr :start_date, Phi::Date
    phi_attr :intervention, Phi::FreeText
    # phi_attr :status,
    phi_attr :responsible_team_member_id, Phi::SmallPopulation


    # belongs_to :careplan, class_name: Health::Careplan.name
    # delegate :patient, to: :careplan
    belongs_to :patient
    belongs_to :editor, class_name: User.name, foreign_key: :user_id

    validates_presence_of :name, :number, :type

    scope :variable_goals, -> { where(type: self.available_types_for_variable_goals)}

    def self.type_name
      raise 'Implement in sub-class'
    end

    def type_name
      self.class.type_name
    end


    def self.available_types
      [
        Health::Goal::Clinical,
        Health::Goal::Housing,
        Health::Goal::Social,
        Health::Goal::SelfManagement,
      ]
    end

    def self.available_types_for_variable_goals
      self.available_types - [Health::Goal::Housing, Health::Goal::SelfManagement]
    end

    def self.next_available_number(careplan_id:)
      Health::Goal::Base.where(careplan_id: careplan_id).maximum(:number) + 1 || 1
    end

    def self.available_numbers
      (1..4)
    end
  end
end