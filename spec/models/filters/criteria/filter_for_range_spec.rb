require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForRange do
  include_context 'filter criteria setup'

  let(:require_service) { false }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      start: start_date,
      end: end_date,
      require_service_during_range: require_service,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  let!(:enrollments) do
    [
      # Enrollment fully within range
      create_enrollment_for_client(create(:hud_client),
                                   first_date_in_program: start_date + 1.day,
                                   last_date_in_program: end_date - 1.day),
      # Enrollment overlapping start of range
      create_enrollment_for_client(create(:hud_client),
                                   first_date_in_program: start_date - 1.month,
                                   last_date_in_program: start_date + 1.month),
      # Enrollment outside range
      create_enrollment_for_client(create(:hud_client),
                                   first_date_in_program: start_date - 2.months,
                                   last_date_in_program: start_date - 1.month),
    ]
  end

  it_behaves_like 'a criteria that always applies'

  describe '#apply' do
    it 'returns enrollments open during the date range' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
    end

    context 'when requiring service during range' do
      let(:require_service) { true }

      before do
        # Add a service record for the first enrollment
        create(
          :service_history_service,
          service_history_enrollment: enrollments[0],
          client_id: enrollments[0].client_id,
          date: start_date + 2.days,
          homeless: true,
          record_type: :service,
        )
      end

      it 'returns only enrollments with services during range' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
      end
    end
  end
end
