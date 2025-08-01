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
    context 'when no scoring rules exist' do
      it 'raises error when there are no rules' do
        expect(AcHmis::Scoring::Rule.count).to eq(0)

        expect do
          calculator.calculate_score({ 'question_1' => 'Yes' }, owner: owner, user: user)
        end.to raise_error(RuntimeError, /No rules found/).
          and not_change(AcHmis::Scoring::CalculationLog, :count)
      end
    end

    context 'when scoring rules exist' do
      # Set up scoring rules for each algorithm
      let!(:algo_1_rule_1) { AcHmis::Scoring::Rule.create!(link_id: 'question_1', exact_value: 'Yes', weight: 0.5, algorithm: 'alt_aha_1') }
      let!(:algo_1_rule_2) { AcHmis::Scoring::Rule.create!(link_id: 'question_2', min_value: '3', weight: 0.3, algorithm: 'alt_aha_1') }

      let!(:algo_2_rule_1) { AcHmis::Scoring::Rule.create!(link_id: 'question_1', exact_value: 'Yes', weight: 0.4, algorithm: 'alt_aha_2') }
      let!(:algo_2_rule_2) { AcHmis::Scoring::Rule.create!(link_id: 'question_3', exact_value: 'High', weight: 0.6, algorithm: 'alt_aha_2') }

      let!(:algo_3_rule_1) { AcHmis::Scoring::Rule.create!(link_id: 'question_1', exact_value: 'Yes', weight: 0.7, algorithm: 'alt_aha_3') }
      let!(:algo_3_rule_2) { AcHmis::Scoring::Rule.create!(link_id: 'question_4', min_value: '2', weight: 0.8, algorithm: 'alt_aha_3') }

      it 'returns 0 for blank values' do
        score = calculator.calculate_score({}, owner: owner, user: user)
        expect(score).to eq(0)
      end

      it 'calculates combined score from all three algorithms' do
        values = {
          'question_1' => 'Yes',
          'question_2' => 5,
          'question_3' => 'High',
          'question_4' => 3,
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
        expect(details['alt_aha_1']['raw_score']).to eq('0.8') # 0.5 + 0.3
        expect(details['alt_aha_1']['probability']).to be_within(0.001).of(0.689)
        expect(details['alt_aha_1']['points']).to eq(4)

        expect(details['alt_aha_2']['raw_score']).to eq('1.0') # 0.4 + 0.6
        expect(details['alt_aha_2']['probability']).to be_within(0.001).of(0.731)
        expect(details['alt_aha_2']['points']).to eq(4)

        expect(details['alt_aha_3']['raw_score']).to eq('1.5') # 0.7 + 0.8
        expect(details['alt_aha_3']['probability']).to be_within(0.001).of(0.818)
        expect(details['alt_aha_3']['points']).to eq(4)

        expect(details['total_points']).to eq(12) # 4 + 4 + 4
        expect(score).to eq(10) # 12 points converts to score 10
      end
    end
  end
end
