# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForHouseholdType do
  include_context 'filter criteria setup'

  let(:household_type) { nil }
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, household_type: household_type) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  let!(:enrollments) do
    [
      # Adult-only household (30 year old, no children)
      create_enrollment_for_client(
        create(:hud_client),
        age: 30,
        other_clients_under_18: 0,
      ),
      # Adult with children (35 year old with children)
      create_enrollment_for_client(
        create(:hud_client),
        age: 35,
        other_clients_under_18: 2,
      ),
      # Child-only household (15 year old)
      create_enrollment_for_client(
        create(:hud_client),
        age: 15,
        other_clients_under_18: 0,
      ),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :household_type, :without_children

  describe '#apply' do
    context 'when filtering for adult-only households' do
      let(:household_type) { :without_children }

      it 'returns only adult households without children' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
      end
    end

    context 'when filtering for households with children' do
      let(:household_type) { :with_children }

      it 'returns only households with children' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[1].id)
      end
    end

    context 'when filtering for child-only households' do
      let(:household_type) { :only_children }

      it 'returns only child households' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end
  end
end
