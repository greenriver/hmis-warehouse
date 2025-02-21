require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForPriorLivingSituation do
  include_context 'filter criteria setup'

  let(:prior_living_situation_ids) { [1, 16] } # Emergency shelter and Place not meant for habitation
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      prior_living_situation_ids: prior_living_situation_ids,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  let!(:enrollments) do
    [
      # From emergency shelter
      create_enrollment_for_client(create(:hud_client), enrollment_attributes: { LivingSituation: 1 }),
      # From place not meant for habitation
      create_enrollment_for_client(create(:hud_client), enrollment_attributes: { LivingSituation: 16 }),
      # From permanent housing
      create_enrollment_for_client(create(:hud_client), enrollment_attributes: { LivingSituation: 3 }),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :prior_living_situation_ids, [1, 16]

  describe '#apply' do
    it 'filters by prior living situation' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
    end

    context 'with different living situations' do
      let(:prior_living_situation_ids) { [3] } # Permanent housing only

      it 'returns enrollments with matching living situation' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end
  end
end
