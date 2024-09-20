require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
RSpec.describe 'HOPWA CAPER STRMU', type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudUtility2024.funding_sources.invert.fetch('HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance')
  end

  let(:project) do
    create_hopwa_project(funder: funder)
  end

  context 'With one multi-member household served with rental assistance' do
    let!(:household) do
      create_hopwa_eligible_household(
        project: project,
        other_clients: [create(:hud_client, data_source: data_source)],
      )
    end

    let!(:services) do
      household.enrollments.map do |member|
        create_service(
          enrollment: member,
          record_type: hopwa_financial_assistance,
          type_provided: rental_assistance,
          fa_amount: 101,
        )
      end
    end

    it 'reports household breakdown' do
      report = create_report([project])
      run_report(report)
      rows = question_as_rows(question_number: 'Q3', report: report).to_h
      expect(rows.fetch('STRMU Households Total')).to eq(1)
      expect(rows.fetch('How many households were served with STRMU rental assistance only?')).to eq(1)
      expect(rows.fetch('How many households have been served by STRMU for the first time this year?')).to eq(1)
    end

    context 'with a prior enrollments' do
      before(:each) do
        old_enrollment = create(
          :hud_enrollment,
          client: household.hoh.client,
          project: project,
          entry_date: report_start_date - 1.year,
          relationship_to_hoh: 1,
        )
        create(
          :hud_exit,
          enrollment: old_enrollment,
          exit_date: old_enrollment.entry_date,
        )
      end

      it 'counts longevity' do
        report = create_report([project])
        run_report(report)
        rows = question_as_rows(question_number: 'Q3', report: report).to_h
        expect(rows.fetch('How many households have been served by STRMU for the first time this year?')).to eq(0)
        expect(rows.fetch('How many households also received STRMU assistance during the previous year?')).to eq(1)
      end
    end
  end
end
