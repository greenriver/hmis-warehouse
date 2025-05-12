# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForDestination do
  include_context 'filter criteria setup'

  let(:destination_ids) { [101, 302] } # Example destination IDs
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      destination_ids: destination_ids,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create enrollments with different destinations
  let!(:enrollments) do
    [
      create_enrollment_for_client(
        create(:hud_client),
        destination: 101,
        exit_attributes: { Destination: 101 },
      ),
      create_enrollment_for_client(
        create(:hud_client),
        destination: 302,
        exit_attributes: { Destination: 302 },
      ),
      create_enrollment_for_client(
        create(:hud_client),
        destination: 423,
        exit_attributes: { Destination: 423 },
      ),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :destination_ids, [101, 302]

  describe '#apply' do
    it 'filters enrollments by the selected destination IDs' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
    end

    context 'with different destination IDs' do
      let(:destination_ids) { [423] }

      it 'returns enrollments with matching destination' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end

    context 'with empty destination IDs' do
      let(:destination_ids) { [] }

      it 'does not apply the filter' do
        expect(criteria.applies?).to be false
      end
    end
  end
end
