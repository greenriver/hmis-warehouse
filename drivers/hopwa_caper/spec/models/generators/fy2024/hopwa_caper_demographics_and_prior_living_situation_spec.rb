require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
RSpec.describe 'HOPWA CAPER Demographics & Prior Living Situation', type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudUtility2024.funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)')
  end

  let(:project) do
    create_hopwa_project(funder: funder)
  end

  context 'With one household served with rental assistance' do
    let(:household) { create_hopwa_eligible_household(project: project) }
    before(:each) do
      create_service(
        enrollment: household.hoh,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 101,
      )
    end

    it 'reports hopwa qualified individuals demographics' do
      household.hoh.client.update!(
        DOB: today - 20.years,
        Man: 1,
        BlackAfAmerican: 1,
        White: 1,
        DOBDataQuality: 1,
      )
      report = create_report([project])
      run_report(report)
      expect(report.hopwa_caper_enrollments.size).to eq(1)
      rows = question_as_rows(question_number: 'Q1A', report: report)
      table = rows_to_table(rows)
      expect(table['Black/African American & White']['Male 18-30']).to eq(1)
    end

    it 'reports prior living' do
      report = create_report([project])
      run_report(report)
      expect(report.hopwa_caper_enrollments.size).to eq(1)
      rows = question_as_rows(question_number: 'Q1C', report: report).to_h
      expect(rows.fetch("Doesn't know, prefers not to answer, or not collected")).to eq(1)
    end
  end
end
