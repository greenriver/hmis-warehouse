require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForFirstTimeHomelessInPastTwoYears do
  include_context 'filter criteria setup'

  let(:first_time_homeless) { true }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      first_time_homeless: first_time_homeless,
      start: start_date,
      end: end_date,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  let!(:enrollments) do
    [
      # Client with no prior homeless history (should be included)
      create_enrollment_for_client(
        create(:hud_client),
        project_type: 1, # Emergency Shelter
        first_date_in_program: start_date + 1.day,
      ),

      # Client with prior homeless history (should be excluded)
      create_enrollment_for_client(
        client_with_history = create(:hud_client),
        project_type: 1,
        first_date_in_program: start_date - 1.year,
      ),
      create_enrollment_for_client(
        client_with_history,
        project_type: 1,
        first_date_in_program: start_date + 1.day,
      ),

      # Client with only non-homeless history (should be included)
      create_enrollment_for_client(
        client_with_ph = create(:hud_client),
        project_type: 9, # Permanent Housing
        first_date_in_program: start_date - 1.year,
      ),
      create_enrollment_for_client(
        client_with_ph,
        project_type: 1,
        first_date_in_program: start_date + 1.day,
      ),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :first_time_homeless, true

  describe '#apply' do
    it 'filters for first time homeless clients' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(
        enrollments[0].id, # No prior history
        enrollments[4].id, # Only prior PH history
      )
    end

    context 'with different date ranges' do
      let(:start_date) { Date.new(2024, 1, 1) }
      let(:end_date) { Date.new(2024, 12, 31) }

      it 'only considers history within past two years' do
        # Create enrollment outside 2-year window
        old_client = create(:hud_client)
        create_enrollment_for_client(
          old_client,
          project_type: 1,
          first_date_in_program: start_date - 3.years,
          last_date_in_program: start_date - 2.years - 1.day,
        )
        current_enrollment = create_enrollment_for_client(
          old_client,
          project_type: 1,
          first_date_in_program: start_date + 1.day,
        )

        result = criteria.apply(scope)
        expect(result.pluck(:id)).to include(current_enrollment.id)
      end
    end
  end
end
