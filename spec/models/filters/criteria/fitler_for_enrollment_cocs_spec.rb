# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForEnrollmentCocs do
  include_context 'filter criteria setup'

  let(:coc_codes) { ['MA-500', 'NY-600'] }
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, coc_codes: coc_codes) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create enrollments with different CoC codes
  let!(:enrollments) do
    coc_values = ['MA-500', 'NY-600', 'CA-500', nil, 'invalid-coc']

    coc_values.map do |coc|
      create_enrollment_for_client(
        create(:hud_client),
        enrollment_attributes: { EnrollmentCoC: coc },
      )
    end
  end

  it_behaves_like 'a criteria that always applies'

  describe '#apply' do
    it 'includes enrollments with selected CoC codes' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to include(enrollments[0].id, enrollments[1].id)
    end

    it 'includes enrollments with null CoC codes' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to include(enrollments[3].id)
    end

    it 'includes enrollments with invalid CoC codes' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to include(enrollments[4].id)
    end

    it 'excludes enrollments with valid but unselected CoC codes' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).not_to include(enrollments[2].id)
    end

    context 'with different CoC selection' do
      let(:coc_codes) { ['CA-500'] }

      it 'filters based on the updated CoC selection' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to include(enrollments[2].id)
        expect(result.pluck(:id)).not_to include(enrollments[0].id, enrollments[1].id)
      end
    end
  end
end
