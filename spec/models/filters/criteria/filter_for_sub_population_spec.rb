# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForSubPopulation do
  include_context 'filter criteria setup'

  let(:sub_population) { :clients }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      sub_population: sub_population,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create test data for all different types of clients/enrollments
  let!(:veteran_adult) { create(:hud_client, VeteranStatus: 1) }
  let!(:non_veteran_adult) { create(:hud_client, VeteranStatus: 0) }
  let!(:young_adult) { create(:hud_client, VeteranStatus: 0, DOB: 22.years.ago.to_date) }
  let!(:older_adult) { create(:hud_client, VeteranStatus: 0, DOB: 30.years.ago.to_date) }
  let!(:child) { create(:hud_client, VeteranStatus: 0, DOB: 10.years.ago.to_date) }

  # Create enrollments with various household compositions
  let!(:veteran_single_enrollment) do
    create_enrollment_for_client(veteran_adult, head_of_household: true, age: 35, other_clients_under_18: 0)
  end

  let!(:non_veteran_single_enrollment) do
    create_enrollment_for_client(non_veteran_adult, head_of_household: true, age: 30, other_clients_under_18: 0)
  end

  let!(:adult_with_child_enrollment) do
    create_enrollment_for_client(older_adult, head_of_household: true, age: 40, other_clients_under_18: 1)
  end

  let!(:youth_head_with_child_enrollment) do
    create_enrollment_for_client(young_adult, head_of_household: true, age: 22, other_clients_under_18: 1)
  end

  let!(:child_only_enrollment) do
    create_enrollment_for_client(child, head_of_household: true, age: 10, other_clients_under_18: 0)
  end

  it_behaves_like 'a criteria that always applies'

  describe '#apply' do
    # Test each available sub-population
    AvailableSubPopulations.available_sub_populations.values.each do |sub_pop|
      context "with #{sub_pop} filter" do
        let(:sub_population) { sub_pop }

        it 'filters correctly' do
          expect(scope).to receive(sub_pop).and_call_original
          result = criteria.apply(scope)

          # Expectations based on the sub-population
          case sub_pop
          when :veterans
            expect(result.pluck(:id)).to include(veteran_single_enrollment.id)
            expect(result.pluck(:id)).not_to include(non_veteran_single_enrollment.id)
          when :non_veterans
            expect(result.pluck(:id)).not_to include(veteran_single_enrollment.id)
            expect(result.pluck(:id)).to include(non_veteran_single_enrollment.id)
          when :adults_with_children
            expect(result.pluck(:id)).to include(adult_with_child_enrollment.id, youth_head_with_child_enrollment.id)
            expect(result.pluck(:id)).not_to include(veteran_single_enrollment.id, non_veteran_single_enrollment.id)
          when :adults_with_children_youth_hoh
            expect(result.pluck(:id)).to include(youth_head_with_child_enrollment.id)
            expect(result.pluck(:id)).not_to include(adult_with_child_enrollment.id)
          when :adults_with_children_twentyfive_plus_hoh
            expect(result.pluck(:id)).to include(adult_with_child_enrollment.id)
            expect(result.pluck(:id)).not_to include(youth_head_with_child_enrollment.id)
          when :adult_only_households
            expect(result.pluck(:id)).to include(veteran_single_enrollment.id, non_veteran_single_enrollment.id)
            expect(result.pluck(:id)).not_to include(adult_with_child_enrollment.id)
          when :child_only_households
            expect(result.pluck(:id)).to include(child_only_enrollment.id)
            expect(result.pluck(:id)).not_to include(veteran_single_enrollment.id, adult_with_child_enrollment.id)
          when :clients
            # This should include all enrollments
            enrollment_ids = [
              veteran_single_enrollment.id,
              non_veteran_single_enrollment.id,
              adult_with_child_enrollment.id,
              youth_head_with_child_enrollment.id,
              child_only_enrollment.id,
            ]
            expect(result.pluck(:id)).to include(*enrollment_ids)
          else
            raise "#{sub_pop} test not supported"
          end
        end
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
