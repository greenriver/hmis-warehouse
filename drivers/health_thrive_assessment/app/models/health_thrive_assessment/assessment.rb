###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthThriveAssessment
  class Assessment < HealthBase
    phi_patient :patient_id
    phi_attr :user_id, Phi::SmallPopulation
    phi_attr :completed_at, Phi::Date

    belongs_to :patient, optional: true
    belongs_to :user, optional: true

    scope :in_progress, -> { where(completed_on: nil) }

    alias_attribute :completed_at, :completed_on

    enum housing_status: {
      steady: 10,
      at_risk: 20,
      homeless: 30,
    }

    def housing_statuses
      {
        steady: 'I have a steady place to live',
        at_risk: 'I have a place to live today, but I am worried about losing it in the future',
        homeless: 'I do not have a steady place to live (I am temporarily staying with others, in a hotel, in a shelter, living outside on the street, on a beach, in a car, abandoned building, bus or train station, or in a park)',
      }.invert
    end

    enum food_insecurity: {
      never: 10,
      sometimes: 20,
      often: 30,
    }, _prefix: true

    def food_insecurity_responses
      {
        never: 'Never true',
        sometimes: 'Sometimes true',
        often: 'Often true',
      }.invert
    end

    enum food_worries: {
      never: 10,
      sometimes: 20,
      often: 30,
    }, _prefix: true

    def food_worries_responses
      {
        never: 'Never true',
        sometimes: 'Sometimes true',
        often: 'Often true',
      }.invert
    end

    def yes_no
      {
        true => 'Yes',
        false => 'No',
      }.invert
    end

    def question_labels
      {
        housing_status: ['What is your living situation today?', housing_statuses],
        food_insecurity: ["Within the past 12 months, the food you bought just didn't last and you didn't have money to get more.", food_insecurity_responses],
        food_worries: ['Within the past 12 months, you worried whether your food would run out before you got money to buy more.', food_worries_responses],
        trouble_drug_cost: ['Do you have trouble paying for medicines?', yes_no],
        trouble_medical_transportation: ['Do you have trouble gettng transportation to medical appointments?', yes_no],
        trouble_utility_cost: ['Do you have trouble paying your heating or electricity bill?', yes_no],
        trouble_caring_for_family: ['Do you have trouble taking care of a child, family member or friend?', yes_no],
        unemployed: ['Are you currently unemployed and looking for a job?', yes_no],
        interested_in_education: ['Are you interested in more education?', yes_no],
      }
    end

    def help_labels
      {
        help_with_housing: 'Housing / Shelter',
        help_with_food: 'Food',
        help_with_drug_cost: 'Paying for Medicine',
        help_with_medical_transportation: 'Transportation to medical appointments',
        help_with_utilities: 'Utilities',
        help_with_childcare: 'Child care / Daycare',
        help_with_eldercare: 'Care for elder or disabled',
        help_with_job_search: 'Job search / training',
        help_with_education: 'Education',
      }
    end
  end
end
