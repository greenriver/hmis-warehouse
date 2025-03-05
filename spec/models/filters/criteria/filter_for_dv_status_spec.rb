# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForDvStatus do
  include_context 'filter criteria setup'

  let(:dv_status) { [1] } # DV survivor status
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      dv_status: dv_status,
      start: start_date,
      end: end_date,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create enrollments with different DV statuses
  let!(:enrollments) do
    [
      # Enrollment with DV survivor status (1)
      create_enrollment_for_client(
        create(:hud_client),
      ),
      # Enrollment without DV survivor status (0)
      create_enrollment_for_client(
        create(:hud_client),
      ),
      # Enrollment with different DV status (2)
      create_enrollment_for_client(
        create(:hud_client),
      ),
    ]
  end

  before do
    # Create health_and_dv records for each client
    create(
      :hud_health_and_dv,
      PersonalID: enrollments[0].client.PersonalID,
      EnrollmentID: enrollments[0].enrollment_group_id,
      data_source_id: data_source.id,
      InformationDate: start_date + 5.days,
      DomesticViolenceSurvivor: 1,
    )

    create(
      :hud_health_and_dv,
      PersonalID: enrollments[1].client.PersonalID,
      EnrollmentID: enrollments[1].enrollment_group_id,
      data_source_id: data_source.id,
      InformationDate: start_date + 5.days,
      DomesticViolenceSurvivor: 0,
    )

    create(
      :hud_health_and_dv,
      PersonalID: enrollments[2].client.PersonalID,
      EnrollmentID: enrollments[2].enrollment_group_id,
      data_source_id: data_source.id,
      InformationDate: start_date + 5.days,
      DomesticViolenceSurvivor: 2,
    )
  end

  it_behaves_like 'a criteria that applies conditionally', :dv_status, [1]

  describe '#apply' do
    it 'filters enrollments by the selected DV status' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
    end

    context 'with different DV status' do
      let(:dv_status) { [2] }

      it 'returns enrollments with matching DV status' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end

    context 'with multiple DV status values' do
      let(:dv_status) { [0, 2] }

      it 'returns enrollments with any matching DV status' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[1].id, enrollments[2].id)
      end
    end

    context 'with outside date range' do
      before do
        # Create health_and_dv record outside the range
        create(
          :hud_health_and_dv,
          PersonalID: enrollments[0].client.PersonalID,
          EnrollmentID: enrollments[0].enrollment_group_id,
          data_source_id: data_source.id,
          InformationDate: end_date + 10.days,
          DomesticViolenceSurvivor: 1,
        )
      end

      it 'only considers records within the date range' do
        # This should still return the enrollment since it has a record within range
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
      end
    end
  end
end
