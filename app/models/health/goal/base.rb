###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class Goal::Base < HealthBase
    self.table_name = 'health_goals'
    has_paper_trail versions: {class_name: 'Health::HealthVersion'}
    acts_as_paranoid

    phi_patient :patient_id
    phi_attr :id, Phi::OtherIdentifier, "ID of goal"
    phi_attr :user_id, Phi::SmallPopulation, "ID of user"
    # phi_attr :type,
    # phi_attr :number,
    phi_attr :name, Phi::FreeText, "Name of goal"
    phi_attr :associated_dx, Phi::FreeText
    phi_attr :barriers, Phi::FreeText, "Description of barriers to goal"
    phi_attr :provider_plan, Phi::FreeText, "Plan of provider"
    phi_attr :case_manager_plan, Phi::FreeText, "Plan of case manager"
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
    phi_attr :goal_details, Phi::FreeText, "Details of goal"
    phi_attr :problem, Phi::FreeText
    phi_attr :start_date, Phi::Date, "Start date of goal"
    phi_attr :intervention, Phi::FreeText
    # phi_attr :status,
    phi_attr :responsible_team_member_id, Phi::SmallPopulation, "ID of responsible team member"


    # belongs_to :careplan, class_name: 'Health::Careplan', optional: true
    # delegate :patient, to: :careplan
    belongs_to :patient, optional: true
    belongs_to :editor, class_name: 'User', foreign_key: :user_id, optional: true

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
