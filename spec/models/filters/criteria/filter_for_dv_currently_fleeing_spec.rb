# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForDvCurrentlyFleeing do
  include_context 'filter criteria setup'

  let(:currently_fleeing) { [1] } # Yes, currently fleeing
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      currently_fleeing: currently_fleeing,
      start: start_date,
      end: end_date,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create enrollments with different currently fleeing statuses
  let!(:enrollments) do
    fleeing_statuses = [1, 0, 8] # Yes, No, Client doesn't know

    fleeing_statuses.map do |_status|
      create_enrollment_for_client(create(:hud_client))
    end
  end

  before do
    # Create health_and_dv records for each enrollment with different fleeing statuses
    fleeing_statuses = [1, 0, 8]

    fleeing_statuses.each_with_index do |status, index|
      create(
        :hud_health_and_dv,
        PersonalID: enrollments[index].client.PersonalID,
        EnrollmentID: enrollments[index].enrollment_group_id,
        data_source_id: data_source.id,
        InformationDate: start_date + 5.days,
        CurrentlyFleeing: status,
      )
    end
  end

  it_behaves_like 'a criteria that applies conditionally', :currently_fleeing, [1]

  describe '#apply' do
    it 'filters enrollments by the currently fleeing status' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
    end

    context 'with different currently fleeing status' do
      let(:currently_fleeing) { [8] } # Client doesn't know

      it 'returns enrollments with matching status' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end

    context 'with multiple currently fleeing statuses' do
      let(:currently_fleeing) { [0, 8] } # No and Client doesn't know

      it 'returns enrollments with any matching status' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[1].id, enrollments[2].id)
      end
    end

    context 'with record outside date range' do
      before do
        # Create health_and_dv record outside the range
        create(
          :hud_health_and_dv,
          PersonalID: enrollments[0].client.PersonalID,
          EnrollmentID: enrollments[0].enrollment_group_id,
          data_source_id: data_source.id,
          InformationDate: end_date + 10.days,
          CurrentlyFleeing: 1,
        )
      end

      it 'only considers records within the date range' do
        # Should still return the enrollment since it has a record within range
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
      end
    end
  end
end
