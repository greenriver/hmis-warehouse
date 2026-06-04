###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::DrilldownPresenter, type: :model do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user) }
  let(:allow_policy) { GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance }
  let(:deny_policy) { GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance }

  let(:record) do
    create(:hud_report_apr_client,
           report_instance: report,
           first_name: 'Jane',
           last_name: 'Smith',
           personal_id: 'P123',
           destination_client_id: 42,
           ssn: '123-45-6789',
           age: 35,
           dob: Date.new(1990, 6, 15),
           dob_quality: 1,
           sex: 1,
           veteran_status: 0,
           relationship_to_hoh: 1,
           first_date_in_program: Date.new(2026, 1, 1),
           last_date_in_program: Date.new(2026, 3, 15),
           head_of_household: true,
           destination: 435,
           project_type: 1,
           domestic_violence: 0,
           currently_fleeing: 0,
           prior_living_situation: 116,
           mental_health_problem: 1,
           hiv_aids: 0,
           income_from_any_source_at_start: 1,
           income_sources_at_start: { 'Earned' => 500, 'SSI' => 200 },
           household_members: ['Jane Smith', 'John Smith'])
  end

  let(:scope) { HudApr::Fy2020::AprClient.where(id: record.id) }

  before do
    allow(user).to receive(:reporting_policy_for_project).and_return(allow_policy)
  end

  describe '#headers' do
    it 'returns all enrollment fields when no question is specified' do
      presenter = described_class.new(scope, report, user)
      headers = presenter.headers

      expect(headers.keys).to match_array(presenter.send(:enrollment_fields).keys)
    end

    it 'returns all fields with a warning for an unmapped question' do
      expect(Rails.logger).to receive(:warn).with(/No field mapping for "Question 99"/)

      presenter = described_class.new(scope, report, user, question: 'Question 99')
      all_presenter = described_class.new(scope, report, user)

      expect(presenter.headers).to eq(all_presenter.headers)
    end
  end

  describe '#fields_for_question' do
    it 'returns the exact expected fields for each question' do
      expected = {
        'Question 4' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'project_type', 'project_tracking_method'],
        'Question 5' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'age', 'dob', 'parenting_youth', 'veteran_status', 'chronically_homeless', 'date_homeless', 'times_homeless', 'months_homeless'],
        'Question 6' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'ssn', 'name_quality', 'dob_quality', 'ssn_quality', 'race_multi', 'sex', 'veteran_status', 'relationship_to_hoh', 'enrollment_coc', 'disabling_condition', 'indefinite_and_impairs', 'developmental_disability', 'hiv_aids', 'physical_disability', 'chronic_disability', 'mental_health_problem', 'substance_abuse', 'income_date_at_start', 'income_from_any_source_at_start', 'income_from_any_source_at_start_raw', 'income_sources_at_start', 'income_date_at_annual_assessment', 'annual_assessment_in_window', 'income_from_any_source_at_annual_assessment', 'income_from_any_source_at_annual_assessment_raw', 'income_sources_at_annual_assessment', 'income_date_at_exit', 'income_from_any_source_at_exit', 'income_from_any_source_at_exit_raw', 'income_sources_at_exit', 'income_total_at_start', 'income_total_at_annual_assessment', 'income_total_at_exit', 'non_cash_benefits_from_any_source_at_start', 'non_cash_benefits_from_any_source_at_annual_assessment', 'non_cash_benefits_from_any_source_at_exit', 'subsidy_information', 'destination', 'housing_assessment', 'prior_living_situation', 'project_type', 'project_tracking_method', 'enrollment_created', 'exit_created', 'date_of_last_bed_night', 'date_to_street'],
        'Question 7' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'parenting_youth', 'project_type', 'project_tracking_method'],
        'Question 8' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'parenting_youth', 'project_type', 'project_tracking_method'],
        'Question 9' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'parenting_youth', 'project_type', 'project_tracking_method'],
        'Question 10' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'sex', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'age', 'dob', 'project_type', 'project_tracking_method'],
        'Question 11' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'age', 'dob', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'project_type', 'project_tracking_method'],
        'Question 12' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'race_multi', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'project_type', 'project_tracking_method'],
        'Question 13' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'mental_health_problem', 'mental_health_problem_entry', 'mental_health_problem_exit', 'mental_health_problem_latest', 'alcohol_abuse_entry', 'alcohol_abuse_exit', 'alcohol_abuse_latest', 'drug_abuse_entry', 'drug_abuse_exit', 'drug_abuse_latest', 'chronic_disability', 'chronic_disability_entry', 'chronic_disability_exit', 'chronic_disability_latest', 'hiv_aids', 'hiv_aids_entry', 'hiv_aids_exit', 'hiv_aids_latest', 'developmental_disability', 'developmental_disability_entry', 'developmental_disability_exit', 'developmental_disability_latest', 'physical_disability', 'physical_disability_entry', 'physical_disability_exit', 'physical_disability_latest', 'substance_abuse', 'substance_abuse_entry', 'substance_abuse_exit', 'substance_abuse_latest', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'project_type', 'project_tracking_method'],
        'Question 14' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'domestic_violence', 'currently_fleeing', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'project_type', 'project_tracking_method'],
        'Question 15' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'destination', 'housing_assessment', 'prior_living_situation', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in'],
        'Question 16' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'income_date_at_start', 'income_from_any_source_at_start', 'income_from_any_source_at_start_raw', 'income_sources_at_start', 'income_date_at_annual_assessment', 'annual_assessment_in_window', 'income_from_any_source_at_annual_assessment', 'income_from_any_source_at_annual_assessment_raw', 'income_sources_at_annual_assessment', 'income_date_at_exit', 'income_from_any_source_at_exit', 'income_from_any_source_at_exit_raw', 'income_sources_at_exit', 'income_total_at_start', 'income_total_at_annual_assessment', 'income_total_at_exit', 'non_cash_benefits_from_any_source_at_start', 'non_cash_benefits_from_any_source_at_annual_assessment', 'non_cash_benefits_from_any_source_at_exit', 'subsidy_information', 'age', 'dob', 'project_type', 'project_tracking_method'],
        'Question 17' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'income_date_at_start', 'income_from_any_source_at_start', 'income_from_any_source_at_start_raw', 'income_sources_at_start', 'income_date_at_annual_assessment', 'annual_assessment_in_window', 'income_from_any_source_at_annual_assessment', 'income_from_any_source_at_annual_assessment_raw', 'income_sources_at_annual_assessment', 'income_date_at_exit', 'income_from_any_source_at_exit', 'income_from_any_source_at_exit_raw', 'income_sources_at_exit', 'income_total_at_start', 'income_total_at_annual_assessment', 'income_total_at_exit', 'non_cash_benefits_from_any_source_at_start', 'non_cash_benefits_from_any_source_at_annual_assessment', 'non_cash_benefits_from_any_source_at_exit', 'subsidy_information', 'age', 'dob', 'project_type', 'project_tracking_method'],
        'Question 18' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'income_date_at_start', 'income_from_any_source_at_start', 'income_from_any_source_at_start_raw', 'income_sources_at_start', 'income_date_at_annual_assessment', 'annual_assessment_in_window', 'income_from_any_source_at_annual_assessment', 'income_from_any_source_at_annual_assessment_raw', 'income_sources_at_annual_assessment', 'income_date_at_exit', 'income_from_any_source_at_exit', 'income_from_any_source_at_exit_raw', 'income_sources_at_exit', 'income_total_at_start', 'income_total_at_annual_assessment', 'income_total_at_exit', 'non_cash_benefits_from_any_source_at_start', 'non_cash_benefits_from_any_source_at_annual_assessment', 'non_cash_benefits_from_any_source_at_exit', 'subsidy_information', 'age', 'dob', 'project_type', 'project_tracking_method'],
        'Question 19' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'income_date_at_start', 'income_from_any_source_at_start', 'income_from_any_source_at_start_raw', 'income_sources_at_start', 'income_date_at_annual_assessment', 'annual_assessment_in_window', 'income_from_any_source_at_annual_assessment', 'income_from_any_source_at_annual_assessment_raw', 'income_sources_at_annual_assessment', 'income_date_at_exit', 'income_from_any_source_at_exit', 'income_from_any_source_at_exit_raw', 'income_sources_at_exit', 'income_total_at_start', 'income_total_at_annual_assessment', 'income_total_at_exit', 'non_cash_benefits_from_any_source_at_start', 'non_cash_benefits_from_any_source_at_annual_assessment', 'non_cash_benefits_from_any_source_at_exit', 'subsidy_information', 'age', 'dob', 'mental_health_problem', 'mental_health_problem_entry', 'mental_health_problem_exit', 'mental_health_problem_latest', 'alcohol_abuse_entry', 'alcohol_abuse_exit', 'alcohol_abuse_latest', 'drug_abuse_entry', 'drug_abuse_exit', 'drug_abuse_latest', 'chronic_disability', 'chronic_disability_entry', 'chronic_disability_exit', 'chronic_disability_latest', 'hiv_aids', 'hiv_aids_entry', 'hiv_aids_exit', 'hiv_aids_latest', 'developmental_disability', 'developmental_disability_entry', 'developmental_disability_exit', 'developmental_disability_latest', 'physical_disability', 'physical_disability_entry', 'physical_disability_exit', 'physical_disability_latest', 'substance_abuse', 'substance_abuse_entry', 'substance_abuse_exit', 'substance_abuse_latest', 'project_type', 'project_tracking_method'],
        'Question 20' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'income_date_at_start', 'income_from_any_source_at_start', 'income_from_any_source_at_start_raw', 'income_sources_at_start', 'income_date_at_annual_assessment', 'annual_assessment_in_window', 'income_from_any_source_at_annual_assessment', 'income_from_any_source_at_annual_assessment_raw', 'income_sources_at_annual_assessment', 'income_date_at_exit', 'income_from_any_source_at_exit', 'income_from_any_source_at_exit_raw', 'income_sources_at_exit', 'income_total_at_start', 'income_total_at_annual_assessment', 'income_total_at_exit', 'non_cash_benefits_from_any_source_at_start', 'non_cash_benefits_from_any_source_at_annual_assessment', 'non_cash_benefits_from_any_source_at_exit', 'subsidy_information', 'age', 'dob', 'parenting_youth', 'project_type', 'project_tracking_method'],
        'Question 21' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'insurance_from_any_source_at_start', 'insurance_from_any_source_at_annual_assessment', 'insurance_from_any_source_at_exit', 'project_type', 'project_tracking_method'],
        'Question 22' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'destination', 'housing_assessment', 'prior_living_situation', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'project_type', 'project_tracking_method'],
        'Question 23' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'destination', 'housing_assessment', 'prior_living_situation', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'project_type', 'project_tracking_method'],
        'Question 24' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'income_date_at_start', 'income_from_any_source_at_start', 'income_from_any_source_at_start_raw', 'income_sources_at_start', 'income_date_at_annual_assessment', 'annual_assessment_in_window', 'income_from_any_source_at_annual_assessment', 'income_from_any_source_at_annual_assessment_raw', 'income_sources_at_annual_assessment', 'income_date_at_exit', 'income_from_any_source_at_exit', 'income_from_any_source_at_exit_raw', 'income_sources_at_exit', 'income_total_at_start', 'income_total_at_annual_assessment', 'income_total_at_exit', 'non_cash_benefits_from_any_source_at_start', 'non_cash_benefits_from_any_source_at_annual_assessment', 'non_cash_benefits_from_any_source_at_exit', 'subsidy_information', 'annual_assessment_expected', 'housing_assessment', 'ce_assessment_date', 'ce_assessment_type', 'ce_assessment_prioritization_status', 'destination', 'prior_living_situation'],
        'Question 25' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'veteran_status', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'sex', 'age', 'dob', 'mental_health_problem', 'mental_health_problem_entry', 'mental_health_problem_exit', 'mental_health_problem_latest', 'alcohol_abuse_entry', 'alcohol_abuse_exit', 'alcohol_abuse_latest', 'drug_abuse_entry', 'drug_abuse_exit', 'drug_abuse_latest', 'chronic_disability', 'chronic_disability_entry', 'chronic_disability_exit', 'chronic_disability_latest', 'hiv_aids', 'hiv_aids_entry', 'hiv_aids_exit', 'hiv_aids_latest', 'developmental_disability', 'developmental_disability_entry', 'developmental_disability_exit', 'developmental_disability_latest', 'physical_disability', 'physical_disability_entry', 'physical_disability_exit', 'physical_disability_latest', 'substance_abuse', 'substance_abuse_entry', 'substance_abuse_exit', 'substance_abuse_latest', 'income_date_at_start', 'income_from_any_source_at_start', 'income_from_any_source_at_start_raw', 'income_sources_at_start', 'income_date_at_annual_assessment', 'annual_assessment_in_window', 'income_from_any_source_at_annual_assessment', 'income_from_any_source_at_annual_assessment_raw', 'income_sources_at_annual_assessment', 'income_date_at_exit', 'income_from_any_source_at_exit', 'income_from_any_source_at_exit_raw', 'income_sources_at_exit', 'income_total_at_start', 'income_total_at_annual_assessment', 'income_total_at_exit', 'non_cash_benefits_from_any_source_at_start', 'non_cash_benefits_from_any_source_at_annual_assessment', 'non_cash_benefits_from_any_source_at_exit', 'subsidy_information', 'destination', 'housing_assessment', 'prior_living_situation', 'project_type', 'project_tracking_method'],
        'Question 26' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'chronically_homeless', 'date_homeless', 'times_homeless', 'months_homeless', 'sex', 'age', 'dob', 'mental_health_problem', 'mental_health_problem_entry', 'mental_health_problem_exit', 'mental_health_problem_latest', 'alcohol_abuse_entry', 'alcohol_abuse_exit', 'alcohol_abuse_latest', 'drug_abuse_entry', 'drug_abuse_exit', 'drug_abuse_latest', 'chronic_disability', 'chronic_disability_entry', 'chronic_disability_exit', 'chronic_disability_latest', 'hiv_aids', 'hiv_aids_entry', 'hiv_aids_exit', 'hiv_aids_latest', 'developmental_disability', 'developmental_disability_entry', 'developmental_disability_exit', 'developmental_disability_latest', 'physical_disability', 'physical_disability_entry', 'physical_disability_exit', 'physical_disability_latest', 'substance_abuse', 'substance_abuse_entry', 'substance_abuse_exit', 'substance_abuse_latest', 'income_date_at_start', 'income_from_any_source_at_start', 'income_from_any_source_at_start_raw', 'income_sources_at_start', 'income_date_at_annual_assessment', 'annual_assessment_in_window', 'income_from_any_source_at_annual_assessment', 'income_from_any_source_at_annual_assessment_raw', 'income_sources_at_annual_assessment', 'income_date_at_exit', 'income_from_any_source_at_exit', 'income_from_any_source_at_exit_raw', 'income_sources_at_exit', 'income_total_at_start', 'income_total_at_annual_assessment', 'income_total_at_exit', 'non_cash_benefits_from_any_source_at_start', 'non_cash_benefits_from_any_source_at_annual_assessment', 'non_cash_benefits_from_any_source_at_exit', 'subsidy_information', 'project_type', 'project_tracking_method'],
        'Question 27' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'age', 'dob', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'parenting_youth', 'sex', 'mental_health_problem', 'mental_health_problem_entry', 'mental_health_problem_exit', 'mental_health_problem_latest', 'alcohol_abuse_entry', 'alcohol_abuse_exit', 'alcohol_abuse_latest', 'drug_abuse_entry', 'drug_abuse_exit', 'drug_abuse_latest', 'chronic_disability', 'chronic_disability_entry', 'chronic_disability_exit', 'chronic_disability_latest', 'hiv_aids', 'hiv_aids_entry', 'hiv_aids_exit', 'hiv_aids_latest', 'developmental_disability', 'developmental_disability_entry', 'developmental_disability_exit', 'developmental_disability_latest', 'physical_disability', 'physical_disability_entry', 'physical_disability_exit', 'physical_disability_latest', 'substance_abuse', 'substance_abuse_entry', 'substance_abuse_exit', 'substance_abuse_latest', 'income_date_at_start', 'income_from_any_source_at_start', 'income_from_any_source_at_start_raw', 'income_sources_at_start', 'income_date_at_annual_assessment', 'annual_assessment_in_window', 'income_from_any_source_at_annual_assessment', 'income_from_any_source_at_annual_assessment_raw', 'income_sources_at_annual_assessment', 'income_date_at_exit', 'income_from_any_source_at_exit', 'income_from_any_source_at_exit_raw', 'income_sources_at_exit', 'income_total_at_start', 'income_total_at_annual_assessment', 'income_total_at_exit', 'non_cash_benefits_from_any_source_at_start', 'non_cash_benefits_from_any_source_at_annual_assessment', 'non_cash_benefits_from_any_source_at_exit', 'subsidy_information', 'destination', 'housing_assessment', 'prior_living_situation', 'project_type', 'project_tracking_method'],
      }

      expected.each do |question, fields|
        presenter = described_class.new(scope, report, user, question: question)
        actual = presenter.headers.keys

        expect(actual).to match_array(fields), -> {
          missing = fields - actual
          extra = actual - fields
          parts = []
          parts << "missing: #{missing.join(', ')}" if missing.any?
          parts << "extra: #{extra.join(', ')}" if extra.any?
          "#{question} field mismatch — #{parts.join('; ')}"
        }
      end
    end

    it 'only references groups that exist on at least one field' do
      presenter = described_class.new(scope, report, user)
      known_groups = presenter.send(:enrollment_fields).values.flat_map(&:groups).uniq.to_set

      presenter.send(:extra_fields).each do |question, groups|
        all_groups = ([:common] + groups).uniq
        unknown = all_groups.reject { |g| known_groups.include?(g) }
        expect(unknown).to be_empty, "#{question} references unknown groups: #{unknown.join(', ')}"
      end
    end
  end

  describe '#display_value' do
    let(:presenter) { described_class.new(scope, report, user, format: format) }
    let(:format) { :html }

    context 'HUD integer-to-label transforms' do
      it 'transforms destination codes' do
        val = presenter.display_value(record, 'destination')
        expect(val).to be_a(String)
        expect(val).not_to eq('435')
      end

      it 'transforms veteran_status codes' do
        val = presenter.display_value(record, 'veteran_status')
        expect(val).to be_a(String)
        expect(val).not_to eq('0')
      end

      it 'transforms relationship_to_hoh codes' do
        val = presenter.display_value(record, 'relationship_to_hoh')
        expect(val).to be_a(String)
        expect(val).not_to eq('1')
      end

      it 'transforms prior_living_situation codes' do
        val = presenter.display_value(record, 'prior_living_situation')
        expect(val).to be_a(String)
        expect(val).not_to eq('116')
      end

      it 'transforms project_type codes' do
        val = presenter.display_value(record, 'project_type')
        expect(val).to be_a(String)
      end

      it 'transforms sex codes' do
        val = presenter.display_value(record, 'sex')
        expect(val).to be_a(String)
      end

      it 'transforms dob_quality codes' do
        val = presenter.display_value(record, 'dob_quality')
        expect(val).to be_a(String)
        expect(val).not_to eq('1')
      end
    end

    context 'not_collected nil-to-99 fallback' do
      it 'treats nil as Data not collected for fields with not_collected flag' do
        record.update!(destination: nil)
        val = presenter.display_value(record, 'destination')
        expect(val).to be_present
      end
    end

    context 'boolean values' do
      it 'renders booleans with content_tag in HTML' do
        val = presenter.display_value(record, 'head_of_household')
        expect(val).to include('icon-checkmark')
      end

      it 'renders booleans as plain text in Excel' do
        xlsx_presenter = described_class.new(scope, report, user, format: :xlsx)
        val = xlsx_presenter.display_value(record, 'head_of_household')
        expect(val).to eq('Yes')
      end
    end

    context 'complex values' do
      it 'renders Hash values as formatted list in HTML' do
        val = presenter.display_value(record, 'income_sources_at_start')
        expect(val).to include('Earned')
        expect(val).to include('500')
        expect(val).to include('<ul')
      end

      it 'renders Hash values as newline-separated in Excel' do
        xlsx_presenter = described_class.new(scope, report, user, format: :xlsx)
        val = xlsx_presenter.display_value(record, 'income_sources_at_start')
        expect(val).to include('Earned')
        expect(val).to include("\n")
      end

      it 'renders Array values as list in HTML' do
        val = presenter.display_value(record, 'household_members')
        expect(val).to include('<ul')
        expect(val).to include('Jane Smith')
      end

      it 'renders Array values as newline-separated in Excel' do
        xlsx_presenter = described_class.new(scope, report, user, format: :xlsx)
        val = xlsx_presenter.display_value(record, 'household_members')
        expect(val).to include("Jane Smith\nJohn Smith")
      end
    end

    context 'PII masking' do
      it 'shows PII when policy allows' do
        expect(presenter.display_value(record, 'first_name')).to eq('Jane')
        expect(presenter.display_value(record, 'last_name')).to eq('Smith')
        expect(presenter.display_value(record, 'ssn')).to eq('123-45-6789')
        expect(presenter.display_value(record, 'dob')).to eq(Date.new(1990, 6, 15))
      end

      it 'masks PII when policy denies' do
        allow(user).to receive(:reporting_policy_for_project).and_return(deny_policy)

        expect(presenter.display_value(record, 'first_name')).to eq('Redacted')
        expect(presenter.display_value(record, 'last_name')).to eq('Redacted')
        expect(presenter.display_value(record, 'ssn')).to eq('Redacted')
        expect(presenter.display_value(record, 'dob')).to eq('Redacted')
      end

      it 'masks HIV status when policy denies' do
        record.update!(hiv_aids: 1)
        allow(user).to receive(:reporting_policy_for_project).and_return(deny_policy)

        expect(presenter.display_value(record, 'hiv_aids')).to eq('Redacted')
      end
    end
  end
end

RSpec.describe HudApr::CeAprDrilldownPresenter, type: :model do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user) }
  let(:record) { create(:hud_report_apr_client, report_instance: report) }
  let(:scope) { HudApr::Fy2020::AprClient.where(id: record.id) }

  before do
    allow(user).to receive(:reporting_policy_for_project).
      and_return(GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance)
  end

  describe '#extra_fields' do
    it 'returns the exact expected fields for each question' do
      expected = {
        'Question 5' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'age', 'dob', 'parenting_youth', 'veteran_status', 'chronically_homeless', 'date_homeless', 'times_homeless', 'months_homeless'],
        'Question 6' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'ssn', 'name_quality', 'dob_quality', 'ssn_quality', 'race_multi', 'sex', 'veteran_status', 'relationship_to_hoh', 'enrollment_coc', 'disabling_condition', 'indefinite_and_impairs', 'developmental_disability', 'hiv_aids', 'physical_disability', 'chronic_disability', 'mental_health_problem', 'substance_abuse', 'income_date_at_start', 'income_from_any_source_at_start', 'income_from_any_source_at_start_raw', 'income_sources_at_start', 'income_date_at_annual_assessment', 'annual_assessment_in_window', 'income_from_any_source_at_annual_assessment', 'income_from_any_source_at_annual_assessment_raw', 'income_sources_at_annual_assessment', 'income_date_at_exit', 'income_from_any_source_at_exit', 'income_from_any_source_at_exit_raw', 'income_sources_at_exit', 'income_total_at_start', 'income_total_at_annual_assessment', 'income_total_at_exit', 'non_cash_benefits_from_any_source_at_start', 'non_cash_benefits_from_any_source_at_annual_assessment', 'non_cash_benefits_from_any_source_at_exit', 'subsidy_information', 'destination', 'housing_assessment', 'prior_living_situation', 'project_type', 'project_tracking_method', 'enrollment_created', 'exit_created', 'date_of_last_bed_night', 'date_to_street'],
        'Question 7' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'parenting_youth', 'project_type', 'project_tracking_method'],
        'Question 8' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'parenting_youth', 'project_type', 'project_tracking_method'],
        'Question 9' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'head_of_household_id', 'household_id', 'household_type', 'household_members', 'move_in_date', 'time_to_move_in', 'date_to_street', 'approximate_time_to_move_in', 'ce_assessment_date', 'ce_assessment_type', 'ce_assessment_prioritization_status', 'ce_event_date', 'ce_event_event', 'ce_event_problem_sol_div_rr_result', 'ce_event_referral_case_manage_after', 'ce_event_referral_result', 'project_type', 'project_tracking_method'],
        'Question 10' => ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household', 'ce_assessment_date', 'ce_assessment_type', 'ce_assessment_prioritization_status', 'ce_event_date', 'ce_event_event', 'ce_event_problem_sol_div_rr_result', 'ce_event_referral_case_manage_after', 'ce_event_referral_result', 'project_type', 'project_tracking_method'],
      }

      expected.each do |question, fields|
        presenter = described_class.new(scope, report, user, question: question)
        actual = presenter.headers.keys

        expect(actual).to match_array(fields), -> {
          missing = fields - actual
          extra = actual - fields
          parts = []
          parts << "missing: #{missing.join(', ')}" if missing.any?
          parts << "extra: #{extra.join(', ')}" if extra.any?
          "#{question} field mismatch — #{parts.join('; ')}"
        }
      end
    end

    it 'only references groups that exist on at least one field' do
      presenter = described_class.new(scope, report, user)
      known_groups = presenter.send(:enrollment_fields).values.flat_map(&:groups).uniq.to_set

      presenter.send(:extra_fields).each do |question, groups|
        all_groups = ([:common] + groups).uniq
        unknown = all_groups.reject { |g| known_groups.include?(g) }
        expect(unknown).to be_empty, "#{question} references unknown groups: #{unknown.join(', ')}"
      end
    end
  end
end
