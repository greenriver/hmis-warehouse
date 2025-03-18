# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForRrhMoveIn do
  include_context 'filter criteria setup'

  let(:rrh_move_in) { true }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      rrh_move_in: rrh_move_in,
      start: start_date,
      end: end_date,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create enrollments with different characteristics
  let!(:enrollments) do
    [
      # rrh enrollment with move-in date within the range
      create_enrollment_for_client(
        create(:hud_client),
        project_type: 3, # Permanent Supportive Housing
        move_in_date: start_date + 10.days,
      ),
      # rrh enrollment with move-in date outside the range
      create_enrollment_for_client(
        create(:hud_client),
        project_type: 3, # Permanent Supportive Housing
        move_in_date: end_date + 10.days,
      ),
      # RRH enrollment with move-in date within the range (wrong project type)
      create_enrollment_for_client(
        create(:hud_client),
        project_type: 13, # Rapid Re-housing
        move_in_date: start_date + 20.days,
      ),
      # rrh enrollment without move-in date
      create_enrollment_for_client(
        create(:hud_client),
        project_type: 3, # Permanent Supportive Housing
      ),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :rrh_move_in, true

  describe '#apply' do
    it 'filters rrh enrollments by move-in date within the range' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
    end
  end
end
