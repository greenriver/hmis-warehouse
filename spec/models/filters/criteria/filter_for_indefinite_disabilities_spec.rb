# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForIndefiniteDisabilities do
  include_context 'filter criteria setup'

  let(:indefinite_disabilities) { [1] } # Yes, indefinite and impairs
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      indefinite_disabilities: indefinite_disabilities,
      start: start_date,
      end: end_date,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create enrollments with different indefinite disability statuses
  let!(:enrollments) do
    indefinite_statuses = [1, 0, 2] # Yes, No, Client doesn't know

    indefinite_statuses.map do |_|
      create_enrollment_for_client(create(:hud_client))
    end
  end

  before do
    # Create disability records for each enrollment with different indefinite status
    indefinite_statuses = [1, 0, 2]

    indefinite_statuses.each_with_index do |status, index|
      create(
        :hud_disability,
        PersonalID: enrollments[index].client.PersonalID,
        EnrollmentID: enrollments[index].enrollment_group_id,
        data_source_id: data_source.id,
        InformationDate: start_date + 5.days,
        IndefiniteAndImpairs: status,
        DisabilityType: 5, # Physical
        DisabilityResponse: 1, # Yes
      )
    end
  end

  it_behaves_like 'a criteria that applies conditionally', :indefinite_disabilities, [1]

  describe '#apply' do
    it 'filters enrollments by the indefinite disability status' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
    end

    context 'with different indefinite disability status' do
      let(:indefinite_disabilities) { [2] } # Client doesn't know

      it 'returns enrollments with matching status' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end

    context 'with multiple indefinite disability statuses' do
      let(:indefinite_disabilities) { [0, 2] } # No and Client doesn't know

      it 'returns enrollments with any matching status' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[1].id, enrollments[2].id)
      end
    end

    context 'with record outside date range' do
      before do
        # Create disability record outside the range
        create(
          :hud_disability,
          PersonalID: enrollments[0].client.PersonalID,
          EnrollmentID: enrollments[0].enrollment_group_id,
          data_source_id: data_source.id,
          InformationDate: end_date + 10.days,
          IndefiniteAndImpairs: 1,
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
