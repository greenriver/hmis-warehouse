# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForHeadOfHousehold do
  include_context 'filter criteria setup'

  let(:hoh_only) { true }
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, hoh_only: hoh_only) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create one HOH and one non-HOH enrollment
  let!(:hoh_enrollment) { create_enrollment_for_client(create(:hud_client), head_of_household: true) }
  let!(:non_hoh_enrollment) { create_enrollment_for_client(create(:hud_client), head_of_household: false) }

  it_behaves_like 'a criteria that applies conditionally', :hoh_only, true

  describe '#apply' do
    it 'filters for head of household enrollments' do
      result = criteria.apply(scope)

      expect(result.pluck(:id)).to contain_exactly(hoh_enrollment.id)
    end

    context 'when hoh_only is false' do
      let(:hoh_only) { false }

      it 'does not apply filtering' do
        expect(criteria.applies?).to be false
      end
    end
  end
end
