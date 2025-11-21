# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
RSpec.describe HopwaCaper::Generators::Fy2026::Sheets::DemographicsAndPriorLivingSituationSheet, type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)')
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
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:hoh_client) do
      create(
        :hud_client,
        DOB: today - 20.years,
        DOBDataQuality: 1,
        BlackAfAmerican: 1,
        White: 1,
        Sex: 1,
        data_source: data_source,
      )
    end
    let(:beneficiary_client) do
      create(
        :hud_client,
        DOB: today - 32.years,
        DOBDataQuality: 1,
        White: 1,
        Sex: 0,
        data_source: data_source,
      )
    end

    let!(:hoh_enrollment) do
      create_hiv_positive_enrollment(
        client: hoh_client,
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household_id,
      )
    end

    let!(:beneficiary_enrollment) do
      create_enrollment(
        client: beneficiary_client,
        project: project,
        entry_date: report_start_date,
        household_id: household_id,
        relationship_to_ho_h: 99,
      )
    end

    let(:household_enrollments) { [hoh_enrollment, beneficiary_enrollment] }

    let!(:services) do
      household_enrollments.map do |member|
        create(
          :hud_service,
          enrollment: member,
          record_type: hopwa_financial_assistance,
          type_provided: rental_assistance,
          fa_amount: 101,
          date_provided: member.entry_date,
          data_source: data_source,
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

      hoh_row = report.hopwa_caper_enrollments.find_by(personal_id: hoh_client.PersonalID)
      beneficiary_row = report.hopwa_caper_enrollments.find_by(personal_id: beneficiary_client.PersonalID)
      expect(hoh_row.sex).to eq(1)
      expect(beneficiary_row.sex).to eq(0)

      all_rows = question_as_rows(question_number: 'Q1', report: report)
      flattened_rows = all_rows.flatten
      expect(flattened_rows).to include('Complete the age, sex, race, and ethnicity information for all individuals served with all types of HOPWA assistance.')
      expect(flattened_rows).to include('Of the total number of individuals reported for each racial category, how many also identify as Hispanic?')
      expect(flattened_rows).to include('How many other household members (beneficiaries) are HIV negative or have an unknown HIV status?')

      # hopwa qualified individuals demographics
      rows_to_table(all_rows.slice(2, 11)).yield_self do |table|
        # byebug
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

  context 'with enrollments outside report date range' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:hoh_client) { create(:hud_client, data_source: data_source) }

    let!(:hoh_enrollment) do
      create_hiv_positive_enrollment(
        client: hoh_client,
        project: project,
        entry_date: report_start_date - 60.days,
        household_id: household_id,
      )
    end

    before do
      # Service outside the report date range
      create(
        :hud_service,
        enrollment: hoh_enrollment,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 100,
        date_provided: report_start_date - 10.days,
        data_source: data_source,
      )
    end

    it 'includes enrollment and keeps historical services for downstream lookbacks' do
      report = create_report([project])
      run_report(report)

      # Enrollment is included because it's open during the report period
      expect(report.hopwa_caper_enrollments.size).to eq(1)
      # Historical services are retained so longevity sheets can perform lookbacks.
      expect(
        report.hopwa_caper_services.where(date_provided: report_start_date - 10.days).count,
      ).to eq(1)
    end
  end

  context 'with Hispanic ethnicity demographics' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:hispanic_client) do
      create(
        :hud_client,
        DOB: today - 25.years,
        DOBDataQuality: 1,
        HispanicLatinaeo: 1,
        AmIndAKNative: 1,
        Sex: 1,
        data_source: data_source,
      )
    end

    let!(:hoh_enrollment) do
      create_hiv_positive_enrollment(
        client: hispanic_client,
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household_id,
      )
    end

    before do
      create(
        :hud_service,
        enrollment: hoh_enrollment,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 100,
        date_provided: hoh_enrollment.entry_date,
        data_source: data_source,
      )
    end

    it 'reports Hispanic ethnicity breakdown correctly' do
      report = create_report([project])
      run_report(report)

      expect(report.hopwa_caper_enrollments.size).to eq(1)
      enrollment = report.hopwa_caper_enrollments.first
      expect(enrollment.hiv_positive).to be(true)
      expect(enrollment.races).to include(1) # AmIndAKNative race code

      all_rows = question_as_rows(question_number: 'Q1', report: report)

      # Hispanic ethnicity totals should include the client in the American Indian/Alaskan Native race row
      american_indian_row = all_rows.find { |row| row.first == 'American Indian/Alaskan Native' }
      expect(american_indian_row).to be_present
      expect(american_indian_row.last).to eq(1)
    end
  end

  context 'with unknown or missing demographic data' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:unknown_demographics_client) do
      create(
        :hud_client,
        DOB: nil,
        DOBDataQuality: 99,
        RaceNone: 9,
        Sex: 99,
        data_source: data_source,
      )
    end

    let!(:hoh_enrollment) do
      create_hiv_positive_enrollment(
        client: unknown_demographics_client,
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household_id,
      )
    end

    before do
      create(
        :hud_service,
        enrollment: hoh_enrollment,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 100,
        date_provided: hoh_enrollment.entry_date,
        data_source: data_source,
      )
    end

    it 'handles unknown demographic data gracefully' do
      report = create_report([project])
      run_report(report)

      # Verify the system handles unknown data gracefully without crashing
      expect(report.hopwa_caper_enrollments.size).to eq(1)
      enrollment = report.hopwa_caper_enrollments.first
      expect(enrollment.hiv_positive).to be(true)
      expect(enrollment.dob_quality).to eq(99)
      expect(enrollment.sex).to eq(99)
      expect(enrollment.races).to include(unknown_demographics_client.RaceNone) # Preserve RaceNone response for reporting

      # Verify the report generates without errors
      all_rows = question_as_rows(question_number: 'Q1', report: report)
      expect(all_rows).to be_present
      expect(all_rows.size).to be > 25 # Should have full report structure
    end
  end

  context 'with poor DOB quality but valid age (Issue 4)' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:poor_dob_quality_client) do
      create(
        :hud_client,
        DOB: today - 35.years,
        DOBDataQuality: 8, # Client doesn't know
        White: 1,
        Sex: 1,
        data_source: data_source,
      )
    end

    let!(:hoh_enrollment) do
      create_hiv_positive_enrollment(
        client: poor_dob_quality_client,
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household_id,
      )
    end

    before do
      create(
        :hud_service,
        enrollment: hoh_enrollment,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 100,
        date_provided: hoh_enrollment.entry_date,
        data_source: data_source,
      )
    end

    it 'includes client in age/sex/race breakdown despite poor DOB quality' do
      report = create_report([project])
      run_report(report)

      expect(report.hopwa_caper_enrollments.size).to eq(1)
      enrollment = report.hopwa_caper_enrollments.first
      expect(enrollment.hiv_positive).to be(true)
      expect(enrollment.dob_quality).to eq(8)
      expect(enrollment.age).to eq(34)
      expect(enrollment.sex).to eq(1)

      all_rows = question_as_rows(question_number: 'Q1', report: report)

      # Client should appear in the age/sex/race breakdown table (Male 31-50 & White)
      rows_to_table(all_rows.slice(2, 11)).yield_self do |table|
        expect(table['White']['Male 31-50']).to eq(1)
      end
    end
  end
end
