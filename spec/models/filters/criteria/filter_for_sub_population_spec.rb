# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForSubPopulation do
  include_context 'filter criteria setup'

  let(:sub_population) { :veterans }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      sub_population: sub_population,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Make sure we have the right scope methods available
  before do
    # We need to ensure our scope responds to all the subpopulation methods
    available_sub_populations = [
      :adults_with_children, :adults_with_children_youth_hoh,
      :adults_with_children_twentyfive_plus_hoh, :adult_only_households, :clients,
      :child_only_households, :non_veterans, :veterans
    ]

    available_sub_populations.each do |method|
      allow(scope).to receive(method).and_return(scope)
    end

    # Set up specific return values for our test cases
    allow(scope).to receive(:veterans).and_return(scope.where(id: enrollments[0].id))
    allow(scope).to receive(:non_veterans).and_return(scope.where(id: enrollments[1].id))
    allow(scope).to receive(:adult_only_households).and_return(scope.where(id: enrollments[2].id))
  end

  let!(:enrollments) do
    [
      # Veteran
      create_enrollment_for_client(
        create(:hud_client, VeteranStatus: 1),
        head_of_household: true,
        age: 35,
      ),

      # Non-veteran
      create_enrollment_for_client(
        create(:hud_client, VeteranStatus: 0),
        head_of_household: true,
        age: 30,
      ),

      # Adult-only household
      create_enrollment_for_client(
        create(:hud_client),
        head_of_household: true,
        age: 40,
        other_clients_under_18: 0,
      ),
    ]
  end

  # default params make this filter always apply
  it_behaves_like 'a criteria that always applies'

  describe '#apply' do
    it 'filters for the specified sub population' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
    end

    context 'with non_veterans sub population' do
      let(:sub_population) { :non_veterans }

      it 'returns non-veteran enrollments' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[1].id)
      end
    end

    context 'with adult_only_households sub population' do
      let(:sub_population) { :adult_only_households }

      it 'returns enrollments from adult-only households' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end

    context 'with an invalid sub population' do
      let(:sub_population) { :invalid_sub_population }

      it 'raises an error' do
        expect { criteria.apply(scope) }.to raise_error(/not allowed/)
      end
    end
  end
end
