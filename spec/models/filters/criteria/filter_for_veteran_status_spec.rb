require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForVeteranStatus do
  include_context 'filter criteria setup'

  let(:veteran_statuses) { [1] }
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, veteran_statuses: veteran_statuses) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  let!(:enrollments) do
    [
      create_enrollment_for_client(create(:hud_client, VeteranStatus: 1)),
      create_enrollment_for_client(create(:hud_client, VeteranStatus: 0)),
      create_enrollment_for_client(create(:hud_client, VeteranStatus: 99)),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :veteran_statuses, [1]

  describe '#apply' do
    it 'filters by the selected veteran status' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
    end

    context 'with multiple veteran statuses' do
      let(:veteran_statuses) { [0, 99] }

      it 'returns clients matching any specified status' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[1].id, enrollments[2].id)
      end
    end
  end
end
