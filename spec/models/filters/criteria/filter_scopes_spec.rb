require 'rails_helper'

RSpec.describe Filter::FilterScopes do
  let(:test_class) do
    Class.new do
      include Filter::FilterScopes

      def initialize(filter)
        @filter = filter
      end

      def filter_using_criteria(criteria_ids, scope)
        criteria_ids.reduce(scope) do |current_scope, criterion_id|
          run_applicable_criteria(criterion_id, current_scope)
        end
      end

      def criteria_configuration
        @criteria_configuration ||= Filters::Criteria::Configuration.new
      end
    end
  end

  let(:user) { create(:user) }
  let(:filter) { Filters::FilterBase.new(user_id: user.id) }
  let(:instance) { test_class.new(filter) }
  let(:scope) { double('ActiveRecord::Relation') }

  describe '#filter_using_criteria' do
    let(:criteria_ids) { [:filter_for_age, :filter_for_project_type] }

    it 'applies each criterion to the scope' do
      criteria_ids.each do |criterion_id|
        expect(instance).to receive(:run_applicable_criteria).
          with(criterion_id, anything).
          and_return(scope)
      end

      instance.filter_using_criteria(criteria_ids, scope)
    end

    it 'chains criteria applications' do
      initial_scope = scope
      final_scope = double('Final Scope')

      expect(instance).to receive(:run_applicable_criteria).
        with(criteria_ids[0], initial_scope).
        and_return(scope)

      expect(instance).to receive(:run_applicable_criteria).
        with(criteria_ids[1], scope).
        and_return(final_scope)

      result = instance.filter_using_criteria(criteria_ids, initial_scope)
      expect(result).to eq(final_scope)
    end
  end

  describe '#run_applicable_criteria' do
    let(:criterion_id) { :filter_for_age }
    let(:criterion) { instance_double('Filters::Criteria::FilterForAge') }

    before do
      allow(Filters::Criteria).to receive(:factory).
        with(criterion_id, input: filter, config: instance.criteria_configuration).
        and_return(criterion)
    end

    context 'when criterion applies' do
      before do
        allow(criterion).to receive(:applies?).and_return(true)
      end

      it 'applies the criterion to the scope' do
        filtered_scope = double('Filtered Scope')
        expect(criterion).to receive(:apply).
          with(scope).
          and_return(filtered_scope)

        result = instance.run_applicable_criteria(criterion_id, scope)
        expect(result).to eq(filtered_scope)
      end
    end

    context 'when criterion does not apply' do
      before do
        allow(criterion).to receive(:applies?).and_return(false)
      end

      it 'returns the original scope unchanged' do
        expect(criterion).not_to receive(:apply)

        result = instance.run_applicable_criteria(criterion_id, scope)
        expect(result).to eq(scope)
      end
    end
  end
end
