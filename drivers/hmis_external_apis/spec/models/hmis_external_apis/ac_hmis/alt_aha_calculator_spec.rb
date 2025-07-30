###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::AltAhaCalculator, type: :model do
  let(:calculator) { described_class.new }
  let!(:algorithm1) { create(:ac_hmis_scoring_algorithm) }

  let!(:threshold_1) { create(:ac_hmis_scoring_algorithm_threshold, algorithm: algorithm1, threshold: 0.1, points: 1) }
  let!(:threshold_2) { create(:ac_hmis_scoring_algorithm_threshold, algorithm: algorithm1, threshold: 0.3, points: 2) }
  let!(:threshold_3) { create(:ac_hmis_scoring_algorithm_threshold, algorithm: algorithm1, threshold: 0.5, points: 3) }
  let!(:threshold_4) { create(:ac_hmis_scoring_algorithm_threshold, algorithm: algorithm1, threshold: 0.7, points: 4) }
  let!(:threshold_5) { create(:ac_hmis_scoring_algorithm_threshold, algorithm: algorithm1, threshold: 0.9, points: 5) }

  let!(:abc_yes) { create(:ac_hmis_scoring_rule, link_id: 'has_abc_ever_happened', exact_value: 'Yes', weight: 0.5, algorithm: algorithm1) }
  let!(:abc_no) { create(:ac_hmis_scoring_rule, link_id: 'has_abc_ever_happened', exact_value: 'No', weight: -0.5, algorithm: algorithm1) }
  let!(:abc_refused) { create(:ac_hmis_scoring_rule, link_id: 'has_abc_ever_happened', exact_value: 'Refused', weight: -0.25, algorithm: algorithm1) }

  let!(:xyz_less_than_3) { create(:ac_hmis_scoring_rule, link_id: 'how_many_times_xyz', min_value: 1, max_value: 3, weight: 0.2, algorithm: algorithm1) }
  let!(:xyz_3plus) { create(:ac_hmis_scoring_rule, link_id: 'how_many_times_xyz', min_value: 3, weight: 0.3, algorithm: algorithm1) }

  describe 'simple weighted score calculations' do
    it 'calculates score for yes/no/refused questions' do
      values = { 'has_abc_ever_happened' => 'Yes' }
      score_details = calculator.calculate_algorithm_score(algorithm1, values)
      expect(score_details[:weighted_score].to_f).to eq(0.5)
      # weighted_score=0.5 → logistic_score=0.622 → exceeds 0.5 threshold → 3 points
      expect(score_details[:points]).to eq(3)

      values = { 'has_abc_ever_happened' => 'No' }
      score_details = calculator.calculate_algorithm_score(algorithm1, values)
      expect(score_details[:weighted_score].to_f).to eq(-0.5)
      # weighted_score=-0.5 → logistic_score=0.378 → exceeds 0.3 threshold → 2 points
      expect(score_details[:points]).to eq(2)

      values = { 'has_abc_ever_happened' => 'Refused' }
      score_details = calculator.calculate_algorithm_score(algorithm1, values)
      expect(score_details[:weighted_score].to_f).to eq(-0.25)
      # weighted_score=-0.25 → logistic_score=0.438 → exceeds 0.3 threshold → 2 points
      expect(score_details[:points]).to eq(2)
    end

    it 'calculates score for numeric questions with ranges' do
      # Value in 1-3 range
      values = { 'how_many_times_xyz' => 2 }
      score_details = calculator.calculate_algorithm_score(algorithm1, values)
      expect(score_details[:weighted_score].to_f).to eq(0.2)
      # weighted_score=0.2 → logistic_score=0.550 → exceeds 0.5 threshold → 3 points
      expect(score_details[:points]).to eq(3)

      # Value > 3
      values = { 'how_many_times_xyz' => 4 }
      score_details = calculator.calculate_algorithm_score(algorithm1, values)
      expect(score_details[:weighted_score].to_f).to eq(0.3)
      # weighted_score=0.3 → logistic_score=0.574 → exceeds 0.5 threshold → 3 points
      expect(score_details[:points]).to eq(3)
    end
  end

  describe 'combined score calculations' do
    it 'calculates combined score from multiple questions' do
      # Test combining a yes/no question with a numeric range question
      values = {
        'has_abc_ever_happened' => 'Yes',
        'how_many_times_xyz' => 2,
      }
      score_details = calculator.calculate_algorithm_score(algorithm1, values)
      # Should be 0.5 (yes) + 0.2 (2 in range 1-3) = 0.7
      expect(score_details[:weighted_score].to_f).to eq(0.7)
      # weighted_score=0.7 → logistic_score=0.668 → exceeds 0.5 threshold → 3 points
      expect(score_details[:points]).to eq(3)

      # Test with negative and positive weights
      values = {
        'has_abc_ever_happened' => 'No',
        'how_many_times_xyz' => 5,
      }
      score_details = calculator.calculate_algorithm_score(algorithm1, values)
      # Should be -0.5 (no) + 0.3 (5 >= 3) = -0.2
      expect(score_details[:weighted_score].to_f).to eq(-0.2)
      # weighted_score=-0.2 → logistic_score=0.450 → exceeds 0.3 threshold → 2 points
      expect(score_details[:points]).to eq(2)
    end

    it 'handles edge cases and missing values gracefully' do
      # todo @martha test failure with 3 edge case
      # Test with boundary value (exactly 3 should match the 3+ rule, not the 1-3 rule)
      values = {
        'has_abc_ever_happened' => 'Refused',
        'how_many_times_xyz' => 3,
      }
      score_details = calculator.calculate_algorithm_score(algorithm1, values)
      # Should be -0.25 (refused) + 0.3 (3 matches 3+ rule) = 0.05
      expect(score_details[:weighted_score].to_f).to eq(0.05)
      # weighted_score=0.05 → logistic_score=0.512 → exceeds 0.5 threshold → 3 points
      expect(score_details[:points]).to eq(3)

      # Test with unmatched values (should only score for matched rules)
      values = {
        'has_abc_ever_happened' => 'Unknown Response',  # No matching rule
        'how_many_times_xyz' => 2,                      # Matches 1-3 range rule
        'some_other_question' => 'value',               # No matching rule
      }
      score_details = calculator.calculate_algorithm_score(algorithm1, values)
      # Should only score for the xyz question: 0.2
      expect(score_details[:weighted_score].to_f).to eq(0.2)
      # weighted_score=0.2 → logistic_score=0.550 → exceeds 0.5 threshold → 3 points
      expect(score_details[:points]).to eq(3)
    end

    it 'tests higher point thresholds with larger weighted scores' do
      # Create additional scoring rules to achieve higher weighted scores
      create(:ac_hmis_scoring_rule, link_id: 'high_risk_indicator', exact_value: 'Critical', weight: 2.0, algorithm: algorithm1)

      values = {
        'has_abc_ever_happened' => 'Yes',
        'how_many_times_xyz' => 4,
        'high_risk_indicator' => 'Critical',
      }
      score_details = calculator.calculate_algorithm_score(algorithm1, values)
      # Should be 0.5 (yes) + 0.3 (4 >= 3) + 2.0 (critical) = 2.8
      expect(score_details[:weighted_score].to_f).to eq(2.8)
      # weighted_score=2.8 → logistic_score=0.943 → exceeds 0.9 threshold → 5 points
      expect(score_details[:points]).to eq(5)
    end

    it 'tests very low scores that get minimal points' do
      # Create a rule with very negative weight
      create(:ac_hmis_scoring_rule, link_id: 'protective_factor', exact_value: 'Strong', weight: -2.0, algorithm: algorithm1)

      values = {
        'has_abc_ever_happened' => 'No',
        'protective_factor' => 'Strong',
      }
      score_details = calculator.calculate_algorithm_score(algorithm1, values)
      # Should be -0.5 (no) + -2.0 (strong protection) = -2.5
      expect(score_details[:weighted_score].to_f).to eq(-2.5)
      # weighted_score=-2.5 → logistic_score=0.076 → doesn't exceed 0.1 threshold → 0 points
      expect(score_details[:points]).to eq(0)
    end
  end
end
