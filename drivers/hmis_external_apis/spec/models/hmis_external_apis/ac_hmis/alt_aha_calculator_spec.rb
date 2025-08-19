###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::AltAhaCalculator, type: :model do
  let(:owner) { create(:hmis_hud_enrollment) }
  let(:user) { create(:hmis_user) }
  let(:client) { create(:hmis_hud_client, dob: Date.current - 42.years, Woman: 1) }

  describe '#calculate_score' do
    let!(:baseline_rule_1) { create(:ac_hmis_scoring_rule, algorithm: 'alt_aha_1') }
    let!(:baseline_rule_2) { create(:ac_hmis_scoring_rule, algorithm: 'alt_aha_2') }
    let!(:baseline_rule_3) { create(:ac_hmis_scoring_rule, algorithm: 'alt_aha_3') }

    describe 'exact match rule' do
      let!(:exact_match_rule) do
        create(
          :ac_hmis_scoring_rule,
          link_id: 'question_exact',
          form_definition_identifier: 'test_form',
          criteria_type: AcHmis::Scoring::Rule::EXACT_MATCH,
          criteria_config: { 'match_value' => 'Yes' },
          weight: 0.5,
          algorithm: 'alt_aha_1',
        )
      end

      it 'scores when value matches' do
        values = { 'question_exact' => 'Yes' }
        calculator = described_class.new(
          values_by_link_id: values,
          client: client,
          user: user,
          owner: owner,
          form_definition_identifier: 'test_form',
        )

        calculator.calculate_score!

        details = AcHmis::Scoring::CalculationLog.last.calculation_details
        expect(details['alt_aha_1']['raw_score']).to eq('0.5')
        expect(details['alt_aha_2']['raw_score']).to eq('0.0')
        expect(details['alt_aha_3']['raw_score']).to eq('0.0')
      end
    end

    describe 'range rule' do
      let!(:range_rule) do
        create(
          :ac_hmis_scoring_rule,
          link_id: 'question_range',
          form_definition_identifier: 'test_form',
          criteria_type: AcHmis::Scoring::Rule::RANGE,
          criteria_config: { 'gte' => 3 },
          weight: 0.3,
          algorithm: 'alt_aha_2',
        )
      end

      it 'scores when value meets range criteria' do
        values = { 'question_range' => 5 }
        calculator = described_class.new(
          values_by_link_id: values,
          client: client,
          user: user,
          owner: owner,
          form_definition_identifier: 'test_form',
        )

        calculator.calculate_score!

        details = AcHmis::Scoring::CalculationLog.last.calculation_details
        expect(details['alt_aha_1']['raw_score']).to eq('0.0')
        expect(details['alt_aha_2']['raw_score']).to eq('0.3')
        expect(details['alt_aha_3']['raw_score']).to eq('0.0')
      end
    end

    describe 'value rule' do
      let!(:value_rule) do
        create(
          :ac_hmis_scoring_rule,
          link_id: 'question_value',
          form_definition_identifier: 'test_form',
          criteria_type: AcHmis::Scoring::Rule::VALUE,
          criteria_config: {},
          weight: 0.1,
          algorithm: 'alt_aha_3',
        )
      end

      it 'scores using numeric value times weight' do
        values = { 'question_value' => 4 }
        calculator = described_class.new(
          values_by_link_id: values,
          client: client,
          user: user,
          owner: owner,
          form_definition_identifier: 'test_form',
        )

        calculator.calculate_score!

        details = AcHmis::Scoring::CalculationLog.last.calculation_details
        expect(details['alt_aha_1']['raw_score']).to eq('0.0')
        expect(details['alt_aha_2']['raw_score']).to eq('0.0')
        expect(details['alt_aha_3']['raw_score']).to eq('0.4')
      end
    end

    describe 'include rule' do
      let!(:include_rule) do
        create(
          :ac_hmis_scoring_rule,
          link_id: 'question_include',
          form_definition_identifier: 'test_form',
          criteria_type: AcHmis::Scoring::Rule::INCLUDE,
          criteria_config: { 'include' => 'option_b' },
          weight: 0.6,
          algorithm: 'alt_aha_1',
        )
      end

      it 'scores when array includes target value' do
        values = { 'question_include' => ['option_a', 'option_b', 'option_c'] }
        calculator = described_class.new(
          values_by_link_id: values,
          client: client,
          user: user,
          owner: owner,
          form_definition_identifier: 'test_form',
        )

        calculator.calculate_score!

        details = AcHmis::Scoring::CalculationLog.last.calculation_details
        expect(details['alt_aha_1']['raw_score']).to eq('0.6')
        expect(details['alt_aha_2']['raw_score']).to eq('0.0')
        expect(details['alt_aha_3']['raw_score']).to eq('0.0')
      end

      it 'does not score when array does not include target value' do
        values = { 'question_include' => ['option_a', 'option_c'] }
        calculator = described_class.new(
          values_by_link_id: values,
          client: client,
          user: user,
          owner: owner,
          form_definition_identifier: 'test_form',
        )

        calculator.calculate_score!

        details = AcHmis::Scoring::CalculationLog.last.calculation_details
        expect(details['alt_aha_1']['raw_score']).to eq('0.0')
        expect(details['alt_aha_2']['raw_score']).to eq('0.0')
        expect(details['alt_aha_3']['raw_score']).to eq('0.0')
      end
    end
  end
end
