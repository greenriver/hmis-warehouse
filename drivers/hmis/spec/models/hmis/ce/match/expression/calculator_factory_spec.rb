# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::CalculatorFactory do
  describe '.resolve_cohort_id' do
    let!(:cohort_a) { create(:cohort, name: 'Unique Cohort Alpha') }

    it 'returns id for existing numeric id' do
      expect(described_class.resolve_cohort_id(cohort_a.id)).to eq(cohort_a.id)
    end

    it 'returns nil for unknown id' do
      expect(described_class.resolve_cohort_id(9_999_999)).to be_nil
    end

    it 'returns id for exact name match' do
      expect(described_class.resolve_cohort_id('Unique Cohort Alpha')).to eq(cohort_a.id)
    end

    it 'returns nil for unknown name' do
      expect(described_class.resolve_cohort_id('No Such Cohort')).to be_nil
    end

    it 'returns nil for nil' do
      expect(described_class.resolve_cohort_id(nil)).to be_nil
    end

    context 'with duplicate cohort names' do
      let!(:cohort_dup_lower_id) { create(:cohort, name: 'Dup Name') }
      let!(:cohort_dup_higher_id) { create(:cohort, name: 'Dup Name') }

      it 'uses lowest id and warns' do
        expect(Rails.logger).to receive(:warn).with(/Multiple cohorts named "Dup Name"/)
        expect(described_class.resolve_cohort_id('Dup Name')).to eq([cohort_dup_lower_id.id, cohort_dup_higher_id.id].min)
      end
    end
  end

  describe '.build COHORT function' do
    let(:calculator) { described_class.build }
    let!(:cohort) { create(:cohort, name: 'Calc Cohort') }

    it 'evaluates COHORT by id in an expression' do
      expect(calculator.evaluate!("COHORT(#{cohort.id})")).to eq(cohort.id)
    end

    it 'evaluates COHORT by name' do
      expect(calculator.evaluate!('COHORT("Calc Cohort")')).to eq(cohort.id)
    end
  end
end
