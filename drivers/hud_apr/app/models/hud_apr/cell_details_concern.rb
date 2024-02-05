###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::CellDetailsConcern
  extend ActiveSupport::Concern

  included do
    def self.client_class(_question)
      HudApr::Fy2020::AprClient
    end

    def self.extra_fields
      {
        'Question 5' => age_fields + parenting_fields + veteran_fields + homeless_fields,
        'Question 6' => pii_fields + universal_data_fields + financial_fields + housing_fields + project_fields + timeliness_fields + inactive_records_fields,
        'Question 7' => household_fields + parenting_fields + project_fields,
        'Question 8' => household_fields + parenting_fields + project_fields,
        'Question 9' => household_fields + parenting_fields + project_fields + contacts_and_engagement_fields,
        'Question 10' => gender_fields + household_fields + age_fields + project_fields,
        'Question 11' => age_fields + household_fields + project_fields,
        'Question 12' => race_and_ethnicity_fields + household_fields + project_fields,
        'Question 13' => health_fields + household_fields + project_fields,
        'Question 14' => domestic_violence_fields + household_fields + project_fields,
        'Question 15' => housing_fields + household_fields,
        'Question 16' => financial_fields + age_fields + project_fields,
        'Question 17' => financial_fields + age_fields + project_fields,
        'Question 18' => financial_fields + age_fields + project_fields,
        'Question 19' => financial_fields + age_fields + health_fields + project_fields,
        'Question 20' => financial_fields + age_fields + parenting_fields + project_fields,
        'Question 21' => insurance_fields + project_fields,
        'Question 22' => housing_fields + household_fields + project_fields,
        'Question 23' => housing_fields + household_fields + project_fields,
        'Question 24' => household_fields + financial_fields + assessment_fields + housing_fields,
        'Question 25' => veteran_fields + household_fields + gender_fields + age_fields + health_fields + financial_fields + housing_fields + project_fields,
        'Question 26' => household_fields + homeless_fields + gender_fields + age_fields + health_fields + financial_fields + project_fields,
        'Question 27' => age_fields + household_fields + parenting_fields + gender_fields + health_fields + financial_fields + housing_fields + project_fields,
      }
    end

    def self.question_fields(question)
      (common_fields + (extra_fields[question] || all_extra_fields(question))).uniq
    end

    def self.common_fields
      [
        :destination_client_id,
        :personal_id,
        :first_name,
        :last_name,
        :first_date_in_program,
        :last_date_in_program,
        :head_of_household,
      ].freeze
    end

    def self.age_fields
      [
        :age,
        :dob,
      ].freeze
    end

    def self.parenting_fields
      [
        :parenting_youth,
        :parenting_juvenile,
      ].freeze
    end

    def self.veteran_fields
      [
        :veteran_status,
      ].freeze
    end

    def self.homeless_fields
      [
        :chronically_homeless,
        :date_homeless,
        :times_homeless,
        :months_homeless,
      ].freeze
    end

    def self.pii_fields
      [
        :ssn,
        :name_quality,
        :dob_quality,
        :ssn_quality,
        :race,
        :ethnicity,
        :gender,
        :gender_multi,
      ].freeze
    end

    def self.universal_data_fields
      [
        :veteran_status,
        :relationship_to_hoh,
        :enrollment_coc,
        :disabling_condition,
        :indefinite_and_impairs,
        :developmental_disability,
        :hiv_aids,
        :physical_disability,
        :chronic_disability,
        :mental_health_problem,
        :substance_abuse,
        :indefinite_and_impairs,
      ].freeze
    end

    def self.financial_fields
      [
        :income_date_at_start,
        :income_from_any_source_at_start,
        :income_sources_at_start,
        :income_date_at_annual_assessment,
        :annual_assessment_in_window,
        :income_from_any_source_at_annual_assessment,
        :income_sources_at_annual_assessment,
        :income_date_at_exit,
        :income_from_any_source_at_exit,
        :income_sources_at_exit,
        :income_total_at_start,
        :income_total_at_annual_assessment,
        :income_total_at_exit,
        :non_cash_benefits_from_any_source_at_start,
        :non_cash_benefits_from_any_source_at_annual_assessment,
        :non_cash_benefits_from_any_source_at_exit,
        :subsidy_information,
      ].freeze
    end

    def self.assessment_fields
      [
        :annual_assessment_expected,
        :housing_assessment,
        :annual_assessment_in_window,
        :ce_assessment_date,
        :ce_assessment_type,
        :ce_assessment_prioritization_status,
      ].freeze
    end

    def self.housing_fields
      [
        :destination,
        :housing_assessment,
        :prior_living_situation,
      ].freeze
    end

    def self.project_fields
      [
        :project_type,
        :project_tracking_method,
      ].freeze
    end

    def self.timeliness_fields
      [
        :enrollment_created,
        :exit_created,
      ].freeze
    end

    def self.inactive_records_fields
      [
        :date_of_last_bed_night,
        :date_to_street,
      ].freeze
    end

    def self.household_fields
      [
        :head_of_household,
        :head_of_household_id,
        :household_id,
        :household_type,
        :household_members,
        :move_in_date,
        :date_to_street,
        :approximate_time_to_move_in,
      ].freeze
    end

    def self.contacts_and_engagement_fields
      [
        # TODO: These should really come from drivers/hud_apr/app/models/hud_apr/fy2020/apr_living_situation.rb
      ].freeze
    end

    def self.gender_fields
      [
        :gender,
        :gender_multi,
      ].freeze
    end

    def self.race_and_ethnicity_fields
      [
        :race,
        :ethnicity,
      ].freeze
    end

    def self.health_fields
      [
        :mental_health_problem,
        :mental_health_problem_entry,
        :mental_health_problem_exit,
        :mental_health_problem_latest,
        :alcohol_abuse_entry,
        :alcohol_abuse_exit,
        :alcohol_abuse_latest,
        :drug_abuse_entry,
        :drug_abuse_exit,
        :drug_abuse_latest,
        :chronic_disability,
        :chronic_disability_entry,
        :chronic_disability_exit,
        :chronic_disability_latest,
        :hiv_aids,
        :hiv_aids_entry,
        :hiv_aids_exit,
        :hiv_aids_latest,
        :developmental_disability,
        :developmental_disability_entry,
        :developmental_disability_exit,
        :developmental_disability_latest,
        :physical_disability,
        :physical_disability_entry,
        :physical_disability_exit,
        :physical_disability_latest,
        :substance_abuse,
        :substance_abuse_entry,
        :substance_abuse_exit,
        :substance_abuse_latest,
      ].freeze
    end

    def self.domestic_violence_fields
      [
        :domestic_violence,
        :currently_fleeing,
      ].freeze
    end

    def self.insurance_fields
      [
        :insurance_from_any_source_at_start,
        :insurance_from_any_source_at_annual_assessment,
        :insurance_from_any_source_at_exit,
      ].freeze
    end
  end
end
