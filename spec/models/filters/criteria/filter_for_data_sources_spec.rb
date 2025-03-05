# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForDataSources do
  include_context 'filter criteria setup'

  let(:data_source_ids) { [data_source.id] }
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, data_source_ids: data_source_ids) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create an additional data source
  let!(:data_source2) { create(:grda_warehouse_data_source) }
  let!(:data_source3) { create(:grda_warehouse_data_source, visible_in_window: false) } # Non-viewable

  # Create enrollments in different data sources
  let!(:enrollments) do
    [
      # Enrollment in the primary data source
      create_enrollment_for_client(
        create(:hud_client, data_source_id: data_source.id),
        data_source_id: data_source.id,
      ),

      # Enrollment in the second data source
      create_enrollment_for_client(
        create(:hud_client, data_source_id: data_source2.id),
        data_source_id: data_source2.id,
      ),

      # Enrollment in the non-viewable data source
      create_enrollment_for_client(
        create(:hud_client, data_source_id: data_source3.id),
        data_source_id: data_source3.id,
      ),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :data_source_ids, [1]

  describe '#apply' do
    it 'filters enrollments by selected data sources' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
    end

    context 'with different data source selection' do
      let(:data_source_ids) { [data_source2.id] }

      it 'returns enrollments from the selected data source' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[1].id)
      end
    end

    context 'with multiple data sources selected' do
      let(:data_source_ids) { [data_source.id, data_source2.id] }

      it 'returns enrollments from any of the selected data sources' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
      end
    end
  end
end
