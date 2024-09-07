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

  context 'With one multi-member household served with rental assistance' do
    let!(:household) do
      create_hopwa_eligible_household(
        project: project,
        hoh_client: create(:hud_client, DOB: today - 20.years, DOBDataQuality: 1, Man: 1, BlackAfAmerican: 1, White: 1, data_source: data_source),
        other_clients: [create(:hud_client, DOB: today - 32.years, DOBDataQuality: 1, Woman: 1, White: 1, data_source: data_source)],
      )
    end

    before(:each) do
      household.enrollments.each do |member|
        create_service(
          enrollment: member,
          record_type: hopwa_financial_assistance,
          type_provided: rental_assistance,
          fa_amount: 101,
        )
      end
    end

    it 'reports hopwa qualified individuals demographics' do
      report = create_report([project])
      run_report(report)

      expect(report.hopwa_caper_enrollments.size).to eq(2)

      question_as_rows(question_number: 'Q1A', report: report).yield_self do |rows|
        table = rows_to_table(rows)
        expect(table['Black/African American & White']['Male 18-30']).to eq(1)
        expect(table['White']['Female 31-50']).to eq(0)
      end
      question_as_rows(question_number: 'Q1B', report: report).yield_self do |rows|
        table = rows_to_table(rows)
        expect(table['Black/African American & White']['Male 18-30']).to eq(0)
        expect(table['White']['Female 31-50']).to eq(1)
      end
    end

    it 'reports prior living' do
      report = create_report([project])
      run_report(report)
      expect(report.hopwa_caper_enrollments.size).to eq(2)
      rows = question_as_rows(question_number: 'Q1C', report: report).to_h
      expect(rows.fetch("Doesn't know, prefers not to answer, or not collected")).to eq(1)
    end
  end
end
