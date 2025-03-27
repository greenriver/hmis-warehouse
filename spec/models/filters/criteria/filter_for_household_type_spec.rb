# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForHouseholdType do
  include_context 'filter criteria setup'

  let(:household_type) { nil }
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, household_type: household_type) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create clients with different ages and characteristics
  let!(:adult_client) { create(:hud_client, DOB: 30.years.ago.to_date) }
  let!(:adult_client2) { create(:hud_client, DOB: 28.years.ago.to_date) }
  let!(:adult_with_child) { create(:hud_client, DOB: 35.years.ago.to_date) }
  let!(:child_client) { create(:hud_client, DOB: 15.years.ago.to_date) }
  let!(:child_client2) { create(:hud_client, DOB: 10.years.ago.to_date) }
  let!(:child_in_family) { create(:hud_client, DOB: 5.years.ago.to_date) }

  # Create test enrollments for different household types
  let!(:adult_only_hoh) do
    create_enrollment_for_client(
      adult_client,
      age: 30,
      head_of_household: true,
      household_id: 'adult-only-hh',
      other_clients_under_18: 0,
    )
  end

  let!(:adult_only_non_hoh) do
    create_enrollment_for_client(
      adult_client2,
      age: 28,
      head_of_household: false,
      household_id: 'adult-only-hh',
      other_clients_under_18: 0,
    )
  end

  let!(:family_hoh) do
    create_enrollment_for_client(
      adult_with_child,
      age: 35,
      head_of_household: true,
      household_id: 'family-hh',
      other_clients_under_18: 1,
    )
  end

  let!(:family_child) do
    create_enrollment_for_client(
      child_in_family,
      age: 5,
      head_of_household: false,
      household_id: 'family-hh',
      other_clients_over_25: 1,
    )
  end

  let!(:child_only_hoh) do
    create_enrollment_for_client(
      child_client,
      age: 15,
      head_of_household: true,
      household_id: 'child-only-hh',
      other_clients_under_18: 1,
    )
  end

  let!(:child_only_non_hoh) do
    create_enrollment_for_client(
      child_client2,
      age: 10,
      head_of_household: false,
      household_id: 'child-only-hh',
      other_clients_under_18: 0,
    )
  end

  it_behaves_like 'a criteria that applies conditionally', :household_type, :without_children

  describe '#apply' do
    context 'when filtering for adult-only households' do
      let(:household_type) { :without_children }

      it 'returns all members of adult-only households' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(adult_only_hoh.id, adult_only_non_hoh.id)
      end
    end

    context 'when filtering for households with children' do
      let(:household_type) { :with_children }

      it 'returns all members of households with children' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(family_hoh.id, family_child.id)
      end
    end

    context 'when filtering for child-only households' do
      let(:household_type) { :only_children }

      it 'returns all members of child-only households' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(child_only_hoh.id, child_only_non_hoh.id)
      end
    end

    context 'when using "all" household type' do
      let(:household_type) { :all }

      it 'does not apply filtering' do
        expect(criteria.applies?).to be false
      end
    end

    context 'with an invalid household type' do
      let(:household_type) { :invalid_type }

      it 'raises an error' do
        expect { criteria.apply(scope) }.to raise_error(/unknown household_type/)
      end
    end
  end
end
