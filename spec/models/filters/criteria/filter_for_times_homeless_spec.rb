# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForTimesHomeless do
  include_context 'filter criteria setup'

  let(:times_homeless_in_last_three_years) { [1, 3] }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      times_homeless_in_last_three_years: times_homeless_in_last_three_years,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  let!(:enrollments) do
    [
      # Client with 1 time homeless
      create_enrollment_for_client(
        create(:hud_client),
        enrollment_attributes: { TimesHomelessPastThreeYears: 1 },
      ),

      # Client with 3 times homeless
      create_enrollment_for_client(
        create(:hud_client),
        enrollment_attributes: { TimesHomelessPastThreeYears: 3 },
      ),

      # Client with 2 times homeless
      create_enrollment_for_client(
        create(:hud_client),
        enrollment_attributes: { TimesHomelessPastThreeYears: 2 },
      ),

      # Client with 4 or more times homeless
      create_enrollment_for_client(
        create(:hud_client),
        enrollment_attributes: { TimesHomelessPastThreeYears: 4 },
      ),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :times_homeless_in_last_three_years, [1, 3]

  describe '#apply' do
    it 'filters by the selected times homeless' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
    end

    context 'with different times homeless selection' do
      let(:times_homeless_in_last_three_years) { [2, 4] }

      it 'returns enrollments with the specified times homeless values' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id, enrollments[3].id)
      end
    end

    context 'with a single times homeless value' do
      let(:times_homeless_in_last_three_years) { [4] }

      it 'returns only enrollments with exactly that value' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[3].id)
      end
    end
  end
end
