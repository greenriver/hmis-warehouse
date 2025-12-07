# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'

RSpec.describe HopwaCaper::Generators::Fy2026::EnrollmentFilters::IncomeBenefitSourceFilter, type: :model do
  include_context('HOPWA CAPER shared context')

  let(:hopwa_funder) do
    HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)')
  end

  let(:non_hopwa_funder) do
    HudHelper.util('2026').funding_sources.invert.fetch('HUD: CoC - Permanent Supportive Housing')
  end

  let(:hopwa_project) { create_hopwa_project(funder: hopwa_funder) }
  let(:non_hopwa_project) do
    project = create(:hud_project, data_source: data_source, organization: organization)
    create(:hud_project_coc, project: project, data_source_id: data_source.id, CoCCode: coc_code)
    create(:hud_funder, project: project, funder: non_hopwa_funder, data_source: data_source)
    project
  end

  # This test reproduces the bug where household_scoped_filter includes historical enrollments
  # that should be filtered out by date range. Due to the 15-year lookback for longevity,
  # a single report snapshot includes both current and historical enrollments.
  context 'when household has historical enrollments in the same report snapshot' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:hoh_client) { create(:hud_client, data_source: data_source) }
    let(:beneficiary_client) { create(:hud_client, data_source: data_source) }

    # Current enrollments (within report period)
    let!(:hoh_enrollment_current) do
      create_enrollment(
        client: hoh_client,
        project: hopwa_project,
        entry_date: report_start_date + 10.days,
        household_id: household_id,
        relationship_to_ho_h: 1,
      )
    end

    let!(:beneficiary_enrollment_current) do
      create_enrollment(
        client: beneficiary_client,
        project: hopwa_project,
        entry_date: report_start_date + 10.days,
        household_id: household_id,
        relationship_to_ho_h: 2,
      )
    end

    # Historical enrollments (outside report period but within 15-year lookback)
    # These get included in the snapshot for longevity calculations
    let!(:hoh_enrollment_historical) do
      enrollment = create_enrollment(
        client: hoh_client,
        project: hopwa_project,
        entry_date: report_start_date - 2.years,
        household_id: household_id,
        relationship_to_ho_h: 1,
      )
      create(
        :hud_exit,
        enrollment: enrollment,
        exit_date: report_start_date - 1.year,
        data_source: data_source,
      )
      enrollment
    end

    let!(:beneficiary_enrollment_historical) do
      enrollment = create_enrollment(
        client: beneficiary_client,
        project: hopwa_project,
        entry_date: report_start_date - 2.years,
        household_id: household_id,
        relationship_to_ho_h: 2,
      )
      create(
        :hud_exit,
        enrollment: enrollment,
        exit_date: report_start_date - 1.year,
        data_source: data_source,
      )
      enrollment
    end

    before do
      # Mark HoH as HIV+ in both enrollments
      [hoh_enrollment_current, hoh_enrollment_historical].each do |enrollment|
        create(
          :hud_disability,
          disability_type: hiv_positive,
          enrollment: enrollment,
          data_source: data_source,
          disability_response: 1,
        )
      end

      # Current period: HoH has earned income, beneficiary has no income
      create(
        :hud_income_benefit,
        enrollment: hoh_enrollment_current,
        Earned: 1,
        information_date: report_start_date + 15.days,
        data_source: data_source,
        personal_id: hoh_client.PersonalID,
      )
      create(
        :hud_income_benefit,
        enrollment: beneficiary_enrollment_current,
        information_date: report_start_date + 15.days,
        data_source: data_source,
        personal_id: beneficiary_client.PersonalID,
      )

      # Historical period: HoH had no income, beneficiary had SNAP
      create(
        :hud_income_benefit,
        enrollment: hoh_enrollment_historical,
        information_date: report_start_date - 18.months,
        data_source: data_source,
        personal_id: hoh_client.PersonalID,
      )
      create(
        :hud_income_benefit,
        enrollment: beneficiary_enrollment_historical,
        SNAP: 1, # This should NOT affect current period income calculations
        information_date: report_start_date - 18.months,
        data_source: data_source,
        personal_id: beneficiary_client.PersonalID,
      )
    end

    it 'excludes historical enrollments when filtering household income by date range' do
      report = create_report([hopwa_project])
      run_report(report)

      # The report snapshot includes both current and historical enrollments (due to 15-year lookback)
      expect(report.hopwa_caper_enrollments.count).to eq(4) # 2 current + 2 historical

      # Apply date filter to get only current period enrollments
      program_filter = HopwaCaper::Generators::Fy2026::EnrollmentFilters::ProjectFunderFilter.tbra_hopwa
      relevant_enrollments = report.hopwa_caper_enrollments.
        overlapping_range(start_date: report.start_date, end_date: report.end_date).
        merge(program_filter.apply(report.hopwa_caper_enrollments))

      expect(relevant_enrollments.count).to eq(2) # Only current enrollments

      # Apply SNAP filter (which only exists in historical enrollments)
      snap_filter = HopwaCaper::Generators::Fy2026::EnrollmentFilters::IncomeBenefitSourceFilter.new(
        label: 'SNAP',
        types: [:SNAP],
      )

      filtered = snap_filter.apply(relevant_enrollments)

      # Should be 0 because SNAP only exists in historical enrollments
      # If household_members() lost the date filter, it would incorrectly
      # include the historical beneficiary enrollment and find SNAP income
      expect(filtered.count).to eq(0),
                                'Expected no enrollments with SNAP income in current period, but household_scoped_filter may be including historical enrollments'
    end
  end

  # This context tests that project filters are also preserved
  context 'when client has enrollments in different projects in the same snapshot' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:household_id_2) { Hmis::Hud::Base.generate_uuid }

    let(:hoh_client) { create(:hud_client, data_source: data_source) }
    let(:beneficiary_client) { create(:hud_client, data_source: data_source) }

    # HoH in HOPWA project within report period
    let!(:hoh_hopwa_enrollment) do
      create_enrollment(
        client: hoh_client,
        project: hopwa_project,
        entry_date: report_start_date + 10.days,
        household_id: household_id,
        relationship_to_ho_h: 1,
      )
    end

    # Beneficiary in HOPWA project within report period
    let!(:beneficiary_hopwa_enrollment) do
      create_enrollment(
        client: beneficiary_client,
        project: hopwa_project,
        entry_date: report_start_date + 10.days,
        household_id: household_id,
        relationship_to_ho_h: 2,
      )
    end

    # Same beneficiary in a NON-HOPWA project (should NOT affect HOPWA household income)
    let!(:beneficiary_non_hopwa_enrollment) do
      create_enrollment(
        client: beneficiary_client,
        project: non_hopwa_project,
        entry_date: report_start_date + 10.days,
        household_id: household_id_2,
        relationship_to_ho_h: 1,
      )
    end

    before do
      # Mark HoH as HIV+
      create(
        :hud_disability,
        disability_type: hiv_positive,
        enrollment: hoh_hopwa_enrollment,
        data_source: data_source,
        disability_response: 1,
      )

      # HoH in HOPWA project has earned income
      create(
        :hud_income_benefit,
        enrollment: hoh_hopwa_enrollment,
        Earned: 1,
        information_date: report_start_date + 15.days,
        data_source: data_source,
        personal_id: hoh_client.PersonalID,
      )

      # Beneficiary in HOPWA project has no income
      create(
        :hud_income_benefit,
        enrollment: beneficiary_hopwa_enrollment,
        information_date: report_start_date + 15.days,
        data_source: data_source,
        personal_id: beneficiary_client.PersonalID,
      )

      # Beneficiary in NON-HOPWA project has SNAP income
      # This should NOT affect the HOPWA household income calculation
      create(
        :hud_income_benefit,
        enrollment: beneficiary_non_hopwa_enrollment,
        SNAP: 1,
        information_date: report_start_date + 15.days,
        data_source: data_source,
        personal_id: beneficiary_client.PersonalID,
      )
    end

    it 'excludes income from enrollments in other projects' do
      report = create_report([hopwa_project])
      run_report(report)
      _, rows = run_and_extract_rows([hopwa_project], 'Q2')

      # Household should be counted as having earned income (from HoH in HOPWA project)
      expect(rows.fetch('Earned Income from Employment')).to eq(1)

      # count SNAP income from the beneficiary's non-HOPWA enrollment
      expect(rows.fetch('Other Welfare Assistance (Supplemental Nutrition Assistance Program, WIC, TANF, etc.)')).to eq(0)
    end
  end
end
