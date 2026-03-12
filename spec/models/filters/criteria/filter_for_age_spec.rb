# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForAge do
  include_context 'filter criteria setup'

  let(:age_ranges) { [:under_eighteen, :eighteen_to_twenty_four] }
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, age_ranges: age_ranges) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create clients with different ages: child(10), youth(20), adult(40)
  let!(:enrollments) do
    [10, 20, 40].map do |years|
      client = create(:hud_client, DOB: (start_date - years.years), data_source_id: data_source.id)
      create_enrollment_for_client(client)
    end
  end

  it_behaves_like 'a criteria that applies conditionally', :age_ranges, [:under_eighteen, :eighteen_to_twenty_four]

  describe '#apply' do
    it 'filters by the selected age ranges' do
      result = criteria.apply(scope)

      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
    end

    context 'with different age ranges' do
      let(:age_ranges) { [:forty_to_forty_four] }

      it 'filters for the specified age range' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end

    context 'with fourteen_to_seventeen age range' do
      let(:age_ranges) { [:fourteen_to_seventeen] }
      let(:filter) { ::Filters::FilterBase.new(user_id: user.id, start: start_date, age_ranges: age_ranges) }

      it 'filters clients aged 14-17 inclusively' do
        # Create clients aged 13, 14, 15, 16, 17, 18
        # Use exact years without .years helper to avoid leap year calculation issues
        ages_and_enrollments = [13, 14, 15, 16, 17, 18].map do |age|
          dob = Date.new(start_date.year - age, start_date.month, start_date.day)
          client = create(:hud_client, DOB: dob, data_source_id: data_source.id)
          enrollment = create_enrollment_for_client(client)
          [age, enrollment]
        end

        result = criteria.apply(scope)
        result_ids = result.pluck(:id)

        # Should include ages 14-17
        ages_and_enrollments.select { |age, _| age.between?(14, 17) }.each do |age, enrollment|
          expect(result_ids).to include(enrollment.id), "Expected age #{age} to be included"
        end

        # Should exclude ages 13 and 18
        [13, 18].each do |excluded_age|
          enrollment = ages_and_enrollments.find { |age, _| age == excluded_age }.last
          expect(result_ids).not_to include(enrollment.id), "Expected age #{excluded_age} to be excluded"
        end
      end
    end
  end
end
