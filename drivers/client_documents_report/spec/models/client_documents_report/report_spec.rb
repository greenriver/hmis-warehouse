# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientDocumentsReport::Report, type: :model do
  let(:filter_double) do
    double(
      'ReportFilter',
      required_files: [],
      optional_files: [],
      chosen_secondary_cohorts: [],
      apply: ->(scope, _) { scope },
    )
  end

  subject(:report) { described_class.new(filter_double) }

  describe '#additional_client_data' do
    it 'handles nil information_date' do
      client = instance_double('GrdaWarehouse::Hud::Client', id: 1)

      income_with_nil_date = instance_double('IncomeBenefit', information_date: nil, income_from_any_source: 1, total_monthly_income: 100)
      income_with_date = instance_double('IncomeBenefit', information_date: Date.new(2024, 1, 1), income_from_any_source: 1, total_monthly_income: 200)

      enrollment_record = instance_double('GrdaWarehouse::Hud::Enrollment', income_benefits: [income_with_nil_date, income_with_date])

      enrollment = instance_double(
        'GrdaWarehouse::ServiceHistoryEnrollment',
        client_id: client.id,
        client: client,
        entry_date: Date.new(2024, 1, 1),
        enrollment: enrollment_record,
      )

      relation_double = double('Relation')
      allow(relation_double).to receive(:preload).and_return(relation_double)
      allow(relation_double).to receive(:find_each).and_yield(enrollment)
      allow(report).to receive(:enrollments).and_return(relation_double)

      expect do
        data = report.additional_client_data(client)
        expect(data).to be_a(Hash)
      end.not_to raise_error
    end
  end
end
