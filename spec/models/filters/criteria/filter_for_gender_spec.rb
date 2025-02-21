require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForGender do
  include_context 'filter criteria setup'

  let(:genders) { [0, 1] } # Female and Male
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, genders: genders) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  let!(:enrollments) do
    [
      create_enrollment_for_client(create(:hud_client, Gender: 0, Woman: 1)),
      create_enrollment_for_client(create(:hud_client, Gender: 1, Man: 1)),
      create_enrollment_for_client(create(:hud_client, Gender: 4, NonBinary: 1)),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :genders, [0, 1]

  describe '#apply' do
    it 'filters by the selected genders' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
    end

    context 'with different gender selection' do
      let(:genders) { [4] } # Non-binary

      it 'filters for the specified gender' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end
  end
end
