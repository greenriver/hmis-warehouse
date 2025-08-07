###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::AltAhaCalculator, type: :model do
  let(:calculator) { described_class.new }
  let(:owner) { create(:hmis_hud_enrollment) }
  let(:user) { create(:user) }

  describe '#calculate_score' do
    # Test each rule type with one rule per algorithm
    let!(:exact_match_rule) do
      AcHmis::Scoring::Rule.create!(
        link_id: 'question_1',
        form_definition_identifier: 'test_form',
        criteria_type: AcHmis::Scoring::Rule::EXACT_MATCH,
        criteria_config: { 'match_value' => 'Yes' },
        weight: 0.5,
        algorithm: 'alt_aha_1',
      )
    end

    let!(:range_rule) do
      AcHmis::Scoring::Rule.create!(
        link_id: 'question_2',
        form_definition_identifier: 'test_form',
        criteria_type: AcHmis::Scoring::Rule::RANGE,
        criteria_config: { 'gte' => 3 },
        weight: 0.3,
        algorithm: 'alt_aha_2',
      )
    end

    let!(:value_rule) do
      AcHmis::Scoring::Rule.create!(
        link_id: 'question_3',
        form_definition_identifier: 'test_form',
        criteria_type: AcHmis::Scoring::Rule::VALUE,
        criteria_config: {},
        weight: 0.1,
        algorithm: 'alt_aha_3',
      )
    end

    it 'calculates score using different rule types' do
      values = {
        'question_1' => 'Yes',   # exact_match: matches, contributes 0.5
        'question_2' => 5,       # range: >= 3, contributes 0.3
        'question_3' => 4,       # value: 4 * 0.1 = 0.4
      }

      score = calculator.calculate_score(values, owner: owner, user: user)

      # Find the log record
      log = AcHmis::Scoring::CalculationLog.last
      expect(log.namespace).to eq('alt_aha')
      expect(log.final_score).to eq(score)
      expect(log.owner).to eq(owner)
      expect(log.user).to eq(user)

      # Check intermediate calculations
      details = log.calculation_details
      expect(details['alt_aha_1']['raw_score']).to eq('0.5')  # exact match: 0.5 (BigDecimal serialized as string)
      expect(details['alt_aha_2']['raw_score']).to eq('0.3')  # range match: 0.3 (BigDecimal serialized as string)
      expect(details['alt_aha_3']['raw_score']).to eq('0.4')  # value: 4 * 0.1 (BigDecimal serialized as string)

      # Total points should be based on the combined score
      expect(details['total_points']).to eq 8
    end
  end
end
