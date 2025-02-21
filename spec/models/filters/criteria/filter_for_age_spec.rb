require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForAge do
  include_context 'filter criteria setup'

  let(:age_ranges) { [:under_eighteen, :eighteen_to_twenty_four] }
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, age_ranges: age_ranges) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create clients with different ages: child(10), youth(20), adult(40)
  let!(:enrollments) do
    [10, 20, 40].map do |years|
      client = create(:hud_client, DOB: (start_date - years.years), data_source_id: data_source.id)
      create_enrollment_for_client(client)
    end
  end

  it_behaves_like 'a criteria that applies conditionally', :age_ranges, [:under_eighteen, :eighteen_to_twenty_four]

  describe '#apply' do
    it 'filters by the selected age ranges' do
      result = criteria.apply(scope)

      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
    end

    context 'with different age ranges' do
      let(:age_ranges) { [:forty_to_forty_four] }

      it 'filters for the specified age range' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end
  end

  describe 'collect_ages_from_selected_ranges' do
    it 'correctly builds age arrays based on selected ranges' do
      ages = criteria.send(:collect_ages_from_selected_ranges)

      # Should include ages 0-24 (under_eighteen and eighteen_to_twenty_four)
      expect(ages).to include(0, 10, 17, 18, 24)
      expect(ages).not_to include(25, 30)
      expect(ages.count).to eq(25) # 0-24 inclusive
    end
  end
end
