###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::AltAhaV2Calculator, type: :model do
  let(:owner) { create(:hmis_hud_enrollment) }
  let(:user) { create(:hmis_user) }
  let(:client) { create(:hmis_hud_client, dob: Date.current - 42.years, Woman: 1) }
  let(:definition) do
    create(
      :hmis_form_definition,
      role: :CUSTOM_ASSESSMENT,
      identifier: 'test_form',
      definition: { item: [{ type: 'DATE', link_id: 'assessment_date', text: 'Assessment Date', assessment_date: true }] },
    )
  end
  let(:assessment_values) { { 'assessment_date' => '2026-10-28' } }

  # Every algorithm needs at least one rule; these score 0 because their question is unanswered
  let!(:baseline_rules) do
    ['alt_aha_1', 'alt_aha_2', 'alt_aha_3', 'alt_aha_4'].map do |algorithm|
      create(:hmis_scoring_rule, :v2, link_id: 'unanswered', algorithm: algorithm)
    end
  end

  def build_calculator(values)
    described_class.new(values_by_link_id: values, client: client, definition: definition, user: user, owner: owner)
  end

  def raw_score(log, algorithm)
    log.calculation_details[algorithm]['raw_score'].to_d
  end

  describe '#calculate_score' do
    # With raw scores of 0, each probability is set by its intercept alone:
    # alt_aha_1 0.189 (2 points), alt_aha_2 0.052 (1 point), alt_aha_3 0.223 (3 points), alt_aha_4 0.073 (0 points)
    it 'scores each algorithm from its intercept and cutoffs' do
      score, log = build_calculator(assessment_values).calculate_score

      points = ['alt_aha_1', 'alt_aha_2', 'alt_aha_3', 'alt_aha_4'].map { |algorithm| log.calculation_details[algorithm]['points'] }
      expect(points).to eq([2, 1, 3, 0])
      expect(log.calculation_details['total_points']).to eq(6)
      expect(log.calculation_details['model_version']).to eq(2)
      expect(score).to eq(3)
      expect(log.final_score).to eq(3)
    end

    context 'when alt_aha_4 scores 5 points' do
      let!(:alt_aha_4_rule) do
        create(:hmis_scoring_rule, :v2, link_id: 'question_value', criteria_type: Hmis::Scoring::Rule::VALUE, weight: 10, algorithm: 'alt_aha_4')
      end

      it 'counts alt_aha_4 three times' do
        score, log = build_calculator(assessment_values.merge('question_value' => 1)).calculate_score

        expect(log.calculation_details['alt_aha_4']['points']).to eq(5)
        expect(log.calculation_details['total_points']).to eq(2 + 1 + 3 + 3 * 5)
        expect(score).to eq(9)
      end
    end

    it 'ignores model version 1 rules for the same form' do
      create(:hmis_scoring_rule, :v1, link_id: 'question_value', criteria_type: Hmis::Scoring::Rule::VALUE, weight: 10, algorithm: 'alt_aha_1')

      _score, log = build_calculator(assessment_values.merge('question_value' => 1)).calculate_score

      expect(raw_score(log, 'alt_aha_1')).to eq(0)
    end

    describe 'paired rule' do
      let!(:paired_rule) do
        create(
          :hmis_scoring_rule,
          :v2,
          link_id: 'question_a',
          criteria_type: Hmis::Scoring::Rule::EXACT_MATCH,
          criteria_config: { 'match_value' => 'Yes' },
          secondary_link_id: 'question_b',
          secondary_criteria_type: Hmis::Scoring::Rule::EXACT_MATCH,
          secondary_criteria_config: { 'match_value' => 'Yes' },
          weight: 0.7,
          algorithm: 'alt_aha_2',
        )
      end

      it 'scores when both questions match' do
        _score, log = build_calculator(assessment_values.merge('question_a' => 'Yes', 'question_b' => 'Yes')).calculate_score
        expect(raw_score(log, 'alt_aha_2')).to eq(BigDecimal('0.7'))
      end

      it 'does not score when only one question matches' do
        _score, log = build_calculator(assessment_values.merge('question_a' => 'Yes', 'question_b' => 'No')).calculate_score
        expect(raw_score(log, 'alt_aha_2')).to eq(0)
      end
    end

    describe 'days_diff rule' do
      let!(:days_diff_rule) do
        create(
          :hmis_scoring_rule,
          :v2,
          link_id: 'episode_start',
          criteria_type: Hmis::Scoring::Rule::DAYS_DIFF,
          criteria_config: { 'match_value' => 1 },
          weight: 0.4,
          algorithm: 'alt_aha_3',
        )
      end

      it 'counts days from the assessment date in the values' do
        _score, log = build_calculator(assessment_values.merge('episode_start' => '2026-10-27')).calculate_score
        expect(raw_score(log, 'alt_aha_3')).to eq(BigDecimal('0.4'))
      end

      it 'does not score when the days elapsed do not match' do
        _score, log = build_calculator(assessment_values.merge('episode_start' => '2026-10-26')).calculate_score
        expect(raw_score(log, 'alt_aha_3')).to eq(0)
      end
    end

    it 'raises when the assessment date is missing' do
      expect { build_calculator({}).calculate_score }.to raise_error(described_class::MissingAssessmentDateError)
    end

    it 'raises when an algorithm has no rules' do
      baseline_rules.last.destroy!

      expect { build_calculator(assessment_values).calculate_score }.to raise_error(/No rules found for alt_aha_4/)
    end
  end

  describe 'total points to score' do
    {
      0 => 1, 1 => 1, 2 => 2, 5 => 2, 6 => 3, 8 => 3, 9 => 4, 10 => 5,
      11 => 6, 12 => 6, 13 => 7, 16 => 7, 17 => 8, 19 => 8, 20 => 9, 24 => 9, 25 => 10, 30 => 10
    }.each do |total_points, expected_score|
      it "maps #{total_points} points to #{expected_score}" do
        expect(build_calculator(assessment_values).send(:convert_total_points_to_score, total_points)).to eq(expected_score)
      end
    end
  end

  describe '#required_link_ids' do
    before do
      create(
        :hmis_scoring_rule,
        :v2,
        link_id: 'question_a',
        criteria_type: Hmis::Scoring::Rule::EXACT_MATCH,
        criteria_config: { 'match_value' => 'Yes' },
        secondary_link_id: 'question_b',
        secondary_criteria_type: Hmis::Scoring::Rule::EXACT_MATCH,
        secondary_criteria_config: { 'match_value' => 'Yes' },
        algorithm: 'alt_aha_1',
      )
      create(:hmis_scoring_rule, :v2, link_id: 'client_demographics_age', algorithm: 'alt_aha_1')
      create(:hmis_scoring_rule, :v2, link_id: 'client_demographics_gender', criteria_type: Hmis::Scoring::Rule::EXACT_MATCH, criteria_config: { 'match_value' => 0 }, algorithm: 'alt_aha_1')
      create(:hmis_scoring_rule, :v1, link_id: 'v1_question', algorithm: 'alt_aha_1')
    end

    it 'includes both questions of paired rules and excludes client demographics and other versions' do
      expect(build_calculator({}).required_link_ids).to contain_exactly('unanswered', 'question_a', 'question_b')
    end
  end
end
