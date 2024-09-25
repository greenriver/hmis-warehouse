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

  # row[][] => table[row_label][col_label]
  def rows_to_table(rows)
    result = {}
    rows = rows.map(&:dup)
    column_labels = rows.shift[1..] # Remove and store column labels, excluding the first element

    rows.each do |row|
      row_label = row.shift # Remove and store row label
      result[row_label] = {}

      row.each_with_index do |value, index|
        result[row_label][column_labels[index]] = value
      end
    end

    result
  end

  context 'With one multi-member household served with rental assistance' do
    let!(:household) do
      create_hopwa_eligible_household(
        project: project,
        hoh_client: create(:hud_client, DOB: today - 20.years, DOBDataQuality: 1, Man: 1, BlackAfAmerican: 1, White: 1, data_source: data_source),
        other_clients: [create(:hud_client, DOB: today - 32.years, DOBDataQuality: 1, Woman: 1, White: 1, data_source: data_source)],
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

    it 'reports hopwa qualified individuals demographics' do
      report = create_report([project])
      run_report(report)

      expect(report.hopwa_caper_enrollments.size).to eq(2)
      expect(report.hopwa_caper_enrollments.where(hiv_positive: true).size).to eq(1)
      expect(report.hopwa_caper_enrollments.where(ever_prescribed_anti_retroviral_therapy: true).size).to eq(1)
      expect(report.hopwa_caper_enrollments.where(viral_load_suppression: true).size).to eq(1)

      all_rows = question_as_rows(question_number: 'Q1', report: report)

      # hopwa qualified individuals demographics
      rows_to_table(all_rows.slice(2, 11)).yield_self do |table|
        expect(table['Black/African American & White']['Male 18-30']).to eq(1)
        expect(table['White']['Female 31-50']).to eq(0)
      end

      # beneficiaries demographics
      rows_to_table(all_rows.slice(14, 11)).yield_self do |table|
        expect(table['Black/African American & White']['Male 18-30']).to eq(0)
        expect(table['White']['Female 31-50']).to eq(1)
      end

      # demographics & prior living
      all_rows.slice(25, 25).to_h { |ary| ary.slice(0, 2) }.compact_blank.yield_self do |lookup|
        expect(lookup.fetch("How many individuals newly receiving HOPWA assistance didn't report or refused to report their prior living situation?")).to eq(1)
      end
    end
  end
end
