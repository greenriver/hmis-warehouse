require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
RSpec.describe 'HOPWA CAPER PHP', type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudUtility2024.funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing Placement')
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

    it 'reports household count' do
      report = create_report([project])
      run_report(report)
      expect(report.hopwa_caper_enrollments.size).to eq(1)
      rows = question_as_rows(question_number: 'Q4', report: report).to_h
      expect(rows.fetch('How many households were served with PHP assistance?')).to eq(1)
      expect(rows.fetch('What were the HOPWA funds expended for PHP?').to_i).to eq(101)
    end
  end
end
