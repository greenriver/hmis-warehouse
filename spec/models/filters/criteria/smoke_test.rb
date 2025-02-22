require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe 'Filters::Criteria smoke test' do
  include_context 'filter criteria setup'

  # Create minimal enrollment data that most criteria will need
  let!(:enrollment) { create_enrollment_for_client(create(:hud_client)) }

  # Test each criteria class
  Filters::Criteria::DEFINITIONS.each do |criterion_id, definition|
    context (definition[:class_name]).to_s do
      # Create a filter with all possible options enabled
      let(:filter) do
        Filters::FilterBase.new(
          user_id: user.id,
          start: start_date,
          end: end_date,
          # Enable all boolean flags
          active_roi: true,
          ce_cls_as_homeless: true,
          chronic_status: true,
          cohort_ids: [1],
          coordinated_assessment_living_situation_homeless: true,
          first_time_homeless: true,
          hoh_only: true,
          household_type: 'without_children',
          psh_move_in: true,
          require_service_during_range: true,
          returned_to_homelessness_from_permanent_destination: true,
          rrh_move_in: true,
          # Add array values
          days_since_contact_min: 1,
          age_ranges: Filters::FilterBase.available_age_ranges.values,
          coc_codes: ['MA-500'],
          data_source_ids: [data_source.id],
          destination_ids: [1],
          disabilities: [1],
          funder_ids: [1],
          dv_status: 1,
          currently_fleeing: true,
          genders: [0, 1],
          indefinite_disabilities: [1],
          organization_ids: [organization.id],
          prior_living_situation_ids: [1],
          project_group_ids: [1],
          project_ids: [project.id],
          project_type_numbers: [1],
          race_ethnicity_combinations: ['white'],
          races: ['White'],
          times_homeless_in_last_three_years: [1],
          veteran_statuses: [1],
        )
      end

      let(:criteria) do
        Filters::Criteria.factory(
          criterion_id,
          input: filter,
          config: config,
        )
      end

      it 'runs apply() without raising an error' do
        expect { criteria.apply(scope) }.not_to raise_error
      end
    end
  end
end
