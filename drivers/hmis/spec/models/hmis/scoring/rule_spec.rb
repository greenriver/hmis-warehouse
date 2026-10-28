###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Scoring::Rule, type: :model do
  let(:assessment_date) { Date.new(2026, 8, 26) }

  describe '#evaluate' do
    it 'scores a single-criterion rule against one response value' do
      rule = build(:hmis_scoring_rule, :v1, criteria_type: described_class::EXACT_MATCH, criteria_config: { 'match_value' => 'Yes' }, weight: 0.5)
      expect(rule.evaluate('Yes')).to eq(0.5)
      expect(rule.evaluate('No')).to eq(0)
    end

    it 'raises on a paired rule' do
      rule = build(:hmis_scoring_rule, :v2, secondary_link_id: 'other', secondary_criteria_type: described_class::VALUE)
      expect { rule.evaluate('1') }.to raise_error(/use evaluate_values/)
    end

    it 'raises on a days_diff rule' do
      rule = build(:hmis_scoring_rule, :v2, criteria_type: described_class::DAYS_DIFF, criteria_config: {})
      expect { rule.evaluate('2026-08-16') }.to raise_error(/use evaluate_values/)
    end
  end

  describe '#evaluate_values' do
    describe 'value transforms' do
      def value_rule(transform)
        build(:hmis_scoring_rule, :v2, link_id: 'q', criteria_type: described_class::VALUE, criteria_config: { 'transform' => transform }, weight: 1)
      end

      it 'applies each named transform' do
        values = { 'q' => '3' }
        expect(value_rule('square').evaluate_values(values)).to eq(9)
        expect(value_rule('cube').evaluate_values(values)).to eq(27)
        expect(value_rule('quartic').evaluate_values(values)).to eq(81)
        expect(value_rule('log1p').evaluate_values(values)).to be_within(1e-12).of(Math.log(4))
      end

      it 'clamps log1p at zero' do
        expect(value_rule('log1p').evaluate_values({ 'q' => '-2' })).to eq(0)
      end

      it 'contributes zero when unanswered' do
        expect(value_rule('log1p').evaluate_values({})).to eq(0)
      end
    end

    describe 'days_diff' do
      def days_diff_rule(config)
        build(:hmis_scoring_rule, :v2, link_id: 'episode_start', criteria_type: described_class::DAYS_DIFF, criteria_config: config, weight: 1)
      end

      let(:values) { { 'episode_start' => '2026-08-16' } }

      it 'counts days elapsed up to the assessment date' do
        expect(days_diff_rule({}).evaluate_values(values, assessment_date: assessment_date)).to eq(10)
      end

      it 'applies a transform to the days elapsed' do
        expect(days_diff_rule({ 'transform' => 'square' }).evaluate_values(values, assessment_date: assessment_date)).to eq(100)
      end

      it 'matches days elapsed exactly' do
        rule = days_diff_rule({ 'match_value' => 0 })
        expect(rule.evaluate_values({ 'episode_start' => '2026-08-26' }, assessment_date: assessment_date)).to eq(1)
        expect(rule.evaluate_values(values, assessment_date: assessment_date)).to eq(0)
      end

      it 'contributes zero when unanswered' do
        expect(days_diff_rule({}).evaluate_values({}, assessment_date: assessment_date)).to eq(0)
        expect(days_diff_rule({ 'match_value' => 0 }).evaluate_values({}, assessment_date: assessment_date)).to eq(0)
      end

      it 'raises without an assessment date' do
        expect { days_diff_rule({}).evaluate_values(values) }.to raise_error(/requires an assessment date/)
      end
    end

    describe 'paired criteria' do
      let(:rule) do
        build(
          :hmis_scoring_rule,
          :v2,
          link_id: 'admitted',
          criteria_type: described_class::EXACT_MATCH,
          criteria_config: { 'match_value' => 'Yes' },
          secondary_link_id: 'ami',
          secondary_criteria_type: described_class::VALUE,
          secondary_criteria_config: {},
          weight: 0.5,
        )
      end

      it 'multiplies the weight by both terms' do
        expect(rule.evaluate_values({ 'admitted' => 'Yes', 'ami' => '4' })).to eq(2)
      end

      it 'contributes zero when either term is zero' do
        expect(rule.evaluate_values({ 'admitted' => 'No', 'ami' => '4' })).to eq(0)
        expect(rule.evaluate_values({ 'admitted' => 'Yes', 'ami' => '0' })).to eq(0)
      end

      it 'can pair a question with itself' do
        age_rule = build(
          :hmis_scoring_rule,
          :v2,
          link_id: 'age',
          criteria_type: described_class::VALUE,
          criteria_config: { 'transform' => 'cube' },
          secondary_link_id: 'age',
          secondary_criteria_type: described_class::VALUE,
          secondary_criteria_config: { 'transform' => 'log1p' },
          weight: 1,
        )
        expect(age_rule.evaluate_values({ 'age' => 2 })).to be_within(1e-12).of(8 * Math.log(3))
      end
    end
  end

  it 'keeps very small weights through a round trip to the database' do
    rule = create(:hmis_scoring_rule, :v2, weight: '0.0000000000000000035')
    expect(rule.reload.weight).to eq(BigDecimal('0.0000000000000000035'))
  end

  describe 'validation' do
    it 'requires a model_version' do
      expect(build(:hmis_scoring_rule)).not_to be_valid
    end

    it 'rejects an unknown transform' do
      rule = build(:hmis_scoring_rule, :v2, criteria_type: described_class::VALUE, criteria_config: { 'transform' => 'x^2' })
      expect(rule).not_to be_valid
    end

    it 'rejects a days_diff criterion with both a match_value and a transform' do
      rule = build(:hmis_scoring_rule, :v2, criteria_type: described_class::DAYS_DIFF, criteria_config: { 'match_value' => 0, 'transform' => 'square' })
      expect(rule).not_to be_valid
    end

    it 'rejects a days_diff match_value that is not a whole number' do
      rule = build(:hmis_scoring_rule, :v2, criteria_type: described_class::DAYS_DIFF, criteria_config: { 'match_value' => '0' })
      expect(rule).not_to be_valid
    end

    it 'requires a secondary criteria type with a secondary link_id' do
      rule = build(:hmis_scoring_rule, :v2, secondary_link_id: 'other')
      expect(rule).not_to be_valid
    end

    it 'requires a secondary link_id with a secondary criterion' do
      rule = build(:hmis_scoring_rule, :v2, secondary_criteria_type: described_class::VALUE)
      expect(rule).not_to be_valid
    end

    it 'validates the secondary config by its own type' do
      rule = build(:hmis_scoring_rule, :v2, secondary_link_id: 'other', secondary_criteria_type: described_class::EXACT_MATCH, secondary_criteria_config: {})
      expect(rule).not_to be_valid
    end
  end
end
