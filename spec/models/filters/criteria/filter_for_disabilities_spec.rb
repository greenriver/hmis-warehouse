# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForDisabilities do
  include_context 'filter criteria setup'

  let(:disabilities) { [5, 6] } # Example disability types - physical and developmental
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      disabilities: disabilities,
      start: start_date,
      end: end_date,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create enrollments with different disability types
  let!(:enrollments) do
    [
      # Client with physical disability
      create_enrollment_for_client(create(:hud_client)),
      # Client with developmental disability
      create_enrollment_for_client(create(:hud_client)),
      # Client with chronic health condition (different type)
      create_enrollment_for_client(create(:hud_client)),
      # Client with no disabilities
      create_enrollment_for_client(create(:hud_client)),
    ]
  end

  before do
    # Create disability records for each client, matching the first 3 enrollments
    disability_types = [5, 6, 4] # Physical, Developmental, Chronic Health Condition

    disability_types.each_with_index do |disability_type, index|
      create(
        :hud_disability,
        PersonalID: enrollments[index].client.PersonalID,
        EnrollmentID: enrollments[index].enrollment_group_id,
        data_source_id: data_source.id,
        InformationDate: start_date + 5.days,
        DisabilityType: disability_type,
        DisabilityResponse: 1, # Yes
      )
    end

    # The fourth client has no disability record
  end

  it_behaves_like 'a criteria that applies conditionally', :disabilities, [5, 6]

  describe '#apply' do
    it 'filters enrollments by the selected disability types' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
    end

    context 'with different disability type selection' do
      let(:disabilities) { [4] } # Chronic Health Condition

      it 'returns enrollments with matching disability type' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end

    context 'with DisabilityResponse not indicating a disability' do
      before do
        # Update the disability record for client 0 to have a response that is not positive
        GrdaWarehouse::Hud::Disability.where(
          PersonalID: enrollments[0].client.PersonalID,
          EnrollmentID: enrollments[0].enrollment_group_id,
        ).update_all(DisabilityResponse: 0) # No
      end

      it 'excludes enrollments without positive disability responses' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[1].id)
      end
    end

    context 'with disability record outside the date range' do
      before do
        # Create disability record outside the range
        create(
          :hud_disability,
          PersonalID: enrollments[3].client.PersonalID,
          EnrollmentID: enrollments[3].enrollment_group_id,
          data_source_id: data_source.id,
          InformationDate: end_date + 10.days,
          DisabilityType: 5, # Physical
          DisabilityResponse: 1, # Yes
        )
      end

      it 'only considers disability records within the date range' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).not_to include(enrollments[3].id)
      end
    end
  end
end
