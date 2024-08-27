require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
RSpec.describe 'HOPWA CAPER TBRA', type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudUtility2024.funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)')
  end

  let(:project) do
    create_hopwa_project(funder: funder)
  end

  context 'With one household served with rental assistance' do
    let!(:household) { create_hopwa_eligible_household(project: project) }
    let!(:service) do
      create_service(
        enrollment: household.hoh,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 101,
      )
    end

    it 'reports household count, medical insurance, and income_benefit' do
      household.hoh.income_benefits.create!(Medicaid: 1, Earned: 1)
      report = create_report([project])
      run_report(report)
      expect(report.hopwa_caper_enrollments.size).to eq(1)
      rows = question_as_rows(question_number: 'Q2', report: report).to_h
      expect(rows.fetch('How many households were served with HOPWA TBRA assistance?')).to eq(1)
      expect(rows.fetch('What were the total HOPWA funds expended for TBRA rental assistance?').to_i).to eq(101)
      expect(rows.fetch('Earned Income from Employment')).to eq(1)
      expect(rows.fetch('MEDICAID Health Program or local program equivalent')).to eq(1)
    end
  end
end
