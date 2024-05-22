###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthThriveAssessment
  class Assessment < HealthBase
    include Rails.application.routes.url_helpers
    acts_as_paranoid

    phi_patient :patient_id
    phi_attr :user_id, Phi::SmallPopulation
    phi_attr :completed_at, Phi::Date

    belongs_to :patient, class_name: 'Health::Patient', optional: true
    belongs_to :user, optional: true
    has_one :source, class_name: 'Health::EpicThrive', foreign_key: :epic_source_id

    scope :in_progress, -> { where(completed_on: nil) }
    scope :completed_within, ->(range) { where(completed_on: range) }
    scope :newest_first, -> do
      order(arel_table[:completed_on].desc.nulls_first)
    end

    scope :allowed_for_engagement, -> do
      joins(patient: :patient_referrals).
        merge(
          ::Health::PatientReferral.contributing.
            where(
              hpr_t[:enrollment_start_date].lt(Arel.sql("#{arel_table[:completed_on].to_sql} + INTERVAL '1 year'")),
            ),
        )
    end

    alias_attribute :completed_at, :completed_on

    def active?
      completed_on && completed_on >= 1.years.ago
    end

    def completed?
      completed_on.present?
    end

    def positive_sdoh?
      at_risk? || homeless? ||
        food_insecurity_sometimes? || food_insecurity_often? ||
        food_worries_sometimes? || food_worries_often? ||
        trouble_drug_cost? ||
        trouble_medical_transportation? ||
        trouble_utility_cost? ||
        trouble_caring_for_family? ||
        trouble_with_adl? ||
        unemployed? ||
        interested_in_education?
    end

    after_save :record_housing_status

    def record_housing_status
      # If we don't have a patient, or the assessment hasn't been completed, don't record the change
      return unless patient.present? && completed?

      housing_status = if homeless?
        'Homeless'
      elsif at_risk?
        'At Risk'
      else
        'Housing with No Supports'
      end
      patient.record_housing_status(housing_status, on_date: completed_on.to_date)
    end

    def positive_for_homelessness?
      homeless?
    end

    def case_manager
      user&.name || external_name
    end

    enum reporter: {
      patient: 10,
      caregiver: 20,
    }

    def reporter_options
      {
        patient: 'Patient',
        caregiver: 'Parent/Caregiver',
      }.invert
    end

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
        often: 'Often true',
        sometimes: 'Sometimes true',
        never: 'Never true',
      }.invert
    end

    enum food_worries: {
      never: 10,
      sometimes: 20,
      often: 30,
    }, _prefix: true

    def food_worries_responses
      {
        often: 'Often true',
        sometimes: 'Sometimes true',
        never: 'Never true',
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
        reporter: ['I am a', reporter_options],
        housing_status: ['What is your living situation today?', housing_statuses],
        food_insecurity: ["Within the past 12 months, the food you bought just didn't last and you didn't have money to get more.", food_insecurity_responses],
        food_worries: ['Within the past 12 months, you worried whether your food would run out before you got money to buy more.', food_worries_responses],
        trouble_drug_cost: ['Do you have trouble paying for medicines?', yes_no],
        trouble_medical_transportation: ['Do you have trouble gettng transportation to medical appointments?', yes_no],
        trouble_utility_cost: ['Do you have trouble paying your heating or electricity bill?', yes_no],
        trouble_caring_for_family: ['Do you have trouble taking care of a child, family member or friend?', yes_no],
        trouble_with_adl: ['Do you have trouble with day-to-day activities such as bathing, preparing meals, shopping, managing finances, etc.?', yes_no],
        unemployed: ['Are you currently unemployed and looking for a job?', yes_no],
        interested_in_education: ['Are you interested in more education?', yes_no],
      }
    end

    def help_labels
      {
        help_with_housing: 'Housing / Shelter',
        help_with_food: 'Food',
        help_with_drug_cost: 'Paying for Medicine',
        help_with_medical_transportation: 'Transportation',
        help_with_utilities: 'Utilities',
        help_with_childcare: 'Childcare',
        help_with_eldercare: 'Care for elder or disabled',
        # help_with_adl: 'Daily support',
        help_with_job_search: 'Job search / training',
        help_with_education: 'Education',
      }
    end

    def edit_path
      client_health_thrive_assessment_assessment_path(patient.client, self)
    end

    def encounter_report_details
      source = if epic_source_id.present?
        'EPIC'
      else
        'Warehouse'
      end

      {
        source: source,
      }
    end
  end
end
