# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientDocumentsReport::Report, type: :model do
  let(:user) { create(:user) }
  let(:start_date) { Date.new(2024, 1, 1) }
  let(:end_date) { Date.new(2024, 12, 31) }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      start: start_date,
      end: end_date,
      # keep reports simple for this spec
      required_files: [],
      optional_files: [],
    )
  end

  subject(:report) { described_class.new(filter) }

  describe '#additional_client_data' do
    it 'handles nil information_date' do
      client = create(:grda_warehouse_hud_client)

      entry_date = Date.new(2024, 1, 1)
      hud_enrollment = create(
        :grda_warehouse_hud_enrollment,
        PersonalID: client.PersonalID,
        data_source_id: client.data_source_id,
        EntryDate: entry_date,
      )

      create(
        :grda_warehouse_service_history,
        client: client,
        enrollment: hud_enrollment,
        first_date_in_program: entry_date,
        record_type: 'entry',
      )

      create(
        :hud_income_benefit,
        EnrollmentID: hud_enrollment.EnrollmentID,
        PersonalID: client.PersonalID,
        data_source: client.data_source,
        InformationDate: nil,
        IncomeFromAnySource: 1,
        TotalMonthlyIncome: 100,
      )

      create(
        :hud_income_benefit,
        EnrollmentID: hud_enrollment.EnrollmentID,
        PersonalID: client.PersonalID,
        data_source: client.data_source,
        InformationDate: entry_date,
        IncomeFromAnySource: 1,
        TotalMonthlyIncome: 200,
      )

      expect { report.additional_client_data(client) }.not_to raise_error
    end
  end
end
