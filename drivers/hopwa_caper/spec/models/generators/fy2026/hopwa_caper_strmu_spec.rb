# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
RSpec.describe HopwaCaper::Generators::Fy2026::Sheets::StrmuSheet, type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance')
  end

  let(:project) do
    create_hopwa_project(funder: funder)
  end

  context 'with one multi-member household served with rental assistance only' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:hoh_client) { create(:hud_client, data_source: data_source) }
    let(:beneficiary_client) { create(:hud_client, data_source: data_source) }

    let!(:hoh_enrollment) do
      create_enrollment(
        client: hoh_client,
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household_id,
        relationship_to_ho_h: 1,
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

    before do
      create(
        :hud_disability,
        disability_type: hiv_positive,
        enrollment: hoh_enrollment,
        anti_retroviral: 1,
        viral_load_available: 1,
        viral_load: 100,
        data_source: data_source,
        disability_response: 1,
      )
    end

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

    it 'reports household breakdown, income sources, and medical insurance' do
      create_standard_income_benefits(hoh_enrollment)
      _, rows = run_and_extract_rows([project], 'Q3')
      expect(rows.fetch('STRMU Households Total')).to eq(1)
      expect(rows.fetch('How many households were served with STRMU rental assistance only?')).to eq(1)
      expect(rows.fetch('Earned Income from Employment')).to eq(1)
      expect(rows.fetch('MEDICAID Health Program or local program equivalent')).to eq(1)
    end
  end

  context 'with households receiving multiple STRMU assistance types' do
    let(:household1_id) { Hmis::Hud::Base.generate_uuid }
    let(:household2_id) { Hmis::Hud::Base.generate_uuid }

    let(:utility_deposits_code) do
      hud_code(:hopwa_financial_assistance_options, 'Utility deposits')
    end

    let(:utility_payments_code) do
      hud_code(:hopwa_financial_assistance_options, 'Utility payments')
    end

    let!(:household1_enrollment) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household1_id,
      )
    end

    let!(:household2_enrollment) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 2.days,
        household_id: household2_id,
      )
    end

    before do
      # Household 1: receives both rental assistance AND utilities (multiple types)
      create(
        :hud_service,
        enrollment: household1_enrollment,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 500,
        date_provided: household1_enrollment.entry_date,
        data_source: data_source,
      )
      create(
        :hud_service,
        enrollment: household1_enrollment,
        record_type: hopwa_financial_assistance,
        type_provided: utility_deposits_code,
        fa_amount: 150,
        date_provided: household1_enrollment.entry_date,
        data_source: data_source,
      )

      # Household 2: receives only utility assistance (single type)
      create(
        :hud_service,
        enrollment: household2_enrollment,
        record_type: hopwa_financial_assistance,
        type_provided: utility_payments_code,
        fa_amount: 100,
        date_provided: household2_enrollment.entry_date,
        data_source: data_source,
      )
    end

    it 'does not count households receiving multiple codes of the same type in "more than one type"' do
      # Client with both utility deposits and utility payments (one type: utility)
      utility_client = create(:hud_client, data_source: data_source)
      utility_enrollment = create_hiv_positive_enrollment(
        client: utility_client,
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
      create(:hud_service, enrollment: utility_enrollment, record_type: hopwa_financial_assistance,
                           type_provided: hud_code(:hopwa_financial_assistance_options, 'Utility deposits'),
                           fa_amount: 100, date_provided: utility_enrollment.entry_date, data_source: data_source)
      create(:hud_service, enrollment: utility_enrollment, record_type: hopwa_financial_assistance,
                           type_provided: hud_code(:hopwa_financial_assistance_options, 'Utility payments'),
                           fa_amount: 200, date_provided: utility_enrollment.entry_date, data_source: data_source)

      # Client with both rental assistance and security deposits (one type: rental)
      rental_client = create(:hud_client, data_source: data_source)
      rental_enrollment = create_hiv_positive_enrollment(
        client: rental_client,
        project: project,
        entry_date: report_start_date + 2.days,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
      create(:hud_service, enrollment: rental_enrollment, record_type: hopwa_financial_assistance,
                           type_provided: hud_code(:hopwa_financial_assistance_options, 'Rental assistance'),
                           fa_amount: 300, date_provided: rental_enrollment.entry_date, data_source: data_source)
      create(:hud_service, enrollment: rental_enrollment, record_type: hopwa_financial_assistance,
                           type_provided: hud_code(:hopwa_financial_assistance_options, 'Security deposits'),
                           fa_amount: 400, date_provided: rental_enrollment.entry_date, data_source: data_source)

      _, rows = run_and_extract_rows([project], 'Q3')

      # Household 1 from outer before: rental + utility (2 types)
      # Household 2 from outer before: utility (1 type)
      # utility_client: utility + utility (1 type)
      # rental_client: rental + rental (1 type)

      # Total served: 2 (existing) + 2 (new) = 4
      expect(rows.fetch('STRMU Households Total')).to eq(4)

      # Only Household 1 should be in "more than one type"
      expect(rows.fetch('How many households received more than one type of STRMU assistance?')).to eq(1)

      # utility_client should be in "utility assistance only"
      # rental_client should be in "rental assistance only"
      # (Household 2 is also utility assistance only)
      expect(rows.fetch('How many households were served with STRMU utility assistance only?')).to eq(2)
      expect(rows.fetch('How many households were served with STRMU rental assistance only?')).to eq(1)
    end

    it 'correctly categorizes a client with multiple enrollments and different service types' do
      # Create a third client with TWO current enrollments
      client = create(:hud_client, data_source: data_source)

      # Enrollment A: Mortgage assistance
      enrollment_a = create_hiv_positive_enrollment(
        client: client,
        project: project,
        entry_date: report_start_date + 5.days,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
      create(
        :hud_service,
        enrollment: enrollment_a,
        record_type: hopwa_financial_assistance,
        type_provided: hud_code(:hopwa_financial_assistance_options, 'Mortgage assistance'),
        fa_amount: 500,
        date_provided: enrollment_a.entry_date,
        data_source: data_source,
      )

      # Enrollment B: Utility payments
      enrollment_b = create_hiv_positive_enrollment(
        client: client,
        project: project,
        entry_date: report_start_date + 10.days,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
      create(
        :hud_service,
        enrollment: enrollment_b,
        record_type: hopwa_financial_assistance,
        type_provided: hud_code(:hopwa_financial_assistance_options, 'Utility payments'),
        fa_amount: 100,
        date_provided: enrollment_b.entry_date,
        data_source: data_source,
      )

      _, rows = run_and_extract_rows([project], 'Q3')

      # Total served should increase by 1 (total 3: household1, household2, and this new client)
      expect(rows.fetch('STRMU Households Total')).to eq(3)

      # This client should be in "more than one type" (total 2: household1 and this client)
      expect(rows.fetch('How many households received more than one type of STRMU assistance?')).to eq(2)

      # They should NOT be in "mortgage assistance only" or "utility assistance only"
      expect(rows.fetch('How many households were served with STRMU mortgage assistance only?')).to eq(0)
      # (household2 is still utility only)
      expect(rows.fetch('How many households were served with STRMU utility assistance only?')).to eq(1)

      # Expenditures check for all 3 households:
      # Household 1: Rental (500), Utility (150)
      # Household 2: Utility (100)
      # Client (Household 3/4): Mortgage (500), Utility (100)
      # Total Mortgage: 500
      # Total Rental: 500
      # Total Utility: 150 + 100 + 100 = 350
      # Grand Total: 500 + 500 + 350 = 1350
      expect(rows.fetch('STRMU mortgage assistance').to_f).to eq(500)
      expect(rows.fetch('STRMU rental assistance').to_f).to eq(500)
      expect(rows.fetch('STRMU utility assistance').to_f).to eq(350)
      expect(rows.fetch('Total STRMU Expenditures').to_f).to eq(1350)
    end
  end

  context 'with household overlapping report but no services in period' do
    let(:household_with_services_id) { Hmis::Hud::Base.generate_uuid }
    let(:household_no_services_id) { Hmis::Hud::Base.generate_uuid }

    let!(:enrollment_with_services) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 1.day,
        exit_date: nil,
        household_id: household_with_services_id,
      )
    end

    let!(:enrollment_no_services) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date - 30.days, # Overlaps report period
        exit_date: report_end_date + 30.days, # Exits after report period
        household_id: household_no_services_id,
      )
    end

    before do
      # Household 1: Has a service during the reporting period
      create(
        :hud_service,
        enrollment: enrollment_with_services,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 500,
        date_provided: report_start_date + 5.days,
        data_source: data_source,
      )

      # Household 2: Has NO services during the reporting period
      # (Service is BEFORE the report period)
      create(
        :hud_service,
        enrollment: enrollment_no_services,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 500,
        date_provided: report_start_date - 10.days, # Before report period
        data_source: data_source,
      )
    end

    it 'only counts households with services in the reporting period for all sections' do
      # Add income to the household without services
      create_standard_income_benefits(enrollment_no_services)
      # Add income to the household with services
      create_standard_income_benefits(enrollment_with_services)

      _, rows = run_and_extract_rows([project], 'Q3')

      # Only the household with services in the period should be counted
      expect(rows.fetch('STRMU Households Total')).to eq(1)
      expect(rows.fetch('How many households were served with STRMU rental assistance only?')).to eq(1)

      # Income section should also only count the household with services
      expect(rows.fetch('Earned Income from Employment')).to eq(1)

      # The household without services should NOT be in "more than one type"
      expect(rows.fetch('How many households received more than one type of STRMU assistance?')).to eq(0)
    end

    it 'distinguishes between explicit "No Income" and "No Data"' do
      # Add income to the base household with services
      create_standard_income_benefits(enrollment_with_services)

      # Create a third household with services but NO income assessment at all (No Data)
      no_data_hoh = create(:hud_client, data_source: data_source)
      no_data_enrollment = create_hiv_positive_enrollment(
        client: no_data_hoh,
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
      create(
        :hud_service,
        enrollment: no_data_enrollment,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 500,
        date_provided: report_start_date + 10.days,
        data_source: data_source,
      )

      # Create a fourth household with services and an explicit "No Income" assessment
      no_income_hoh = create(:hud_client, data_source: data_source)
      no_income_enrollment = create_hiv_positive_enrollment(
        client: no_income_hoh,
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
      create(
        :hud_service,
        enrollment: no_income_enrollment,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 500,
        date_provided: report_start_date + 10.days,
        data_source: data_source,
      )
      create(
        :hud_income_benefit,
        enrollment: no_income_enrollment,
        IncomeFromAnySource: 0,
        information_date: report_start_date + 5.days,
        data_source: data_source,
      )

      _, rows = run_and_extract_rows([project], 'Q3')

      # Total served should now be 3 (enrollment_with_services, no_data_enrollment, no_income_enrollment)
      expect(rows.fetch('STRMU Households Total')).to eq(3)

      # "No Income" should only be 1 (the one with explicit No)
      # Before the fix, this would have been 2 (including the one with No Data)
      expect(rows.fetch('How many households maintained no sources of income?')).to eq(1)

      # "Any Income" (the total row for sources) should only be 1 (enrollment_with_services)
      # Before the fix, this would have been 3 (including everyone with [])
      expect(rows.fetch('How many households accessed or maintained access to the following sources of income in the past year?')).to eq(1)
    end
  end

  context 'data consistency validations' do
    let(:household1_id) { Hmis::Hud::Base.generate_uuid }
    let(:household2_id) { Hmis::Hud::Base.generate_uuid }
    let(:hoh1) { create(:hud_client, data_source: data_source) }
    let(:hoh2) { create(:hud_client, data_source: data_source) }

    let!(:enrollment1) do
      create_hiv_positive_enrollment(
        client: hoh1,
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household1_id,
        percent_ami: 1, # 0-30%
      )
    end

    let!(:enrollment2) do
      create_hiv_positive_enrollment(
        client: hoh2,
        project: project,
        entry_date: report_start_date + 10.days,
        household_id: household2_id,
        percent_ami: 2, # 31-50%
      )
    end

    before do
      # Financial services for both to make them "served"
      [enrollment1, enrollment2].each do |enrollment|
        create(
          :hud_service,
          enrollment: enrollment,
          record_type: hopwa_financial_assistance,
          type_provided: rental_assistance,
          fa_amount: 500,
          date_provided: enrollment.entry_date,
          data_source: data_source,
        )
      end

      # Set up Income Levels (Denominator match)
      # Household 1: 0-30%
      create(:hud_income_benefit, enrollment: enrollment1, IncomeFromAnySource: 1, TotalMonthlyIncome: 100, data_source: data_source)
      # Household 2: 31-50%
      create(:hud_income_benefit, enrollment: enrollment2, IncomeFromAnySource: 1, TotalMonthlyIncome: 1000, data_source: data_source)

      # Set up Outcomes
      # Household 1: Continuing
      # Household 2: Exit to stable housing
      create(
        :hud_exit,
        enrollment: enrollment2,
        exit_date: report_start_date + 20.days,
        destination: 410, # Rental by client, no ongoing housing subsidy (Stable)
        data_source: data_source,
      )
    end

    it 'ensures Income Levels, Longevity, and Outcomes sum to the total households served' do
      _, rows = run_and_extract_rows([project], 'Q3')
      total_served = rows.fetch('STRMU Households Total')
      expect(total_served).to eq(2)

      # 1. Income Levels (AMI percentages) - should sum to total
      income_level_labels = [
        'What is the number of households with income below 30% of Area Median Income?',
        'What is the number of households with income between 31% and 50% of Area Median Income?',
        'What is the number of households with income between 51% and 80% of Area Median Income?',
      ]
      income_sum = income_level_labels.sum { |label| rows.fetch(label).to_i }
      expect(income_sum).to eq(total_served)

      # 2. Longevity - should sum to total
      longevity_labels = [
        'How many households have been served by STRMU for the first time this year?',
        'How many households also received STRMU assistance during the previous STRMU eligibility period?',
        'How many households received STRMU assistance more than twice during the previous five eligibility periods?',
        'How many households received STRMU assistance during the last five consecutive eligibility periods?',
      ]
      longevity_sum = longevity_labels.sum { |label| rows.fetch(label).to_i }
      expect(longevity_sum).to eq(total_served)

      # 3. Housing Outcomes - should sum to total (continuing + all exit categories)
      # Note: We sum all destination categories from ExitDestinationFilter.all_destinations
      outcome_labels = [
        'How many households continued receiving this type of HOPWA assistance into the next year?',
      ] + HopwaCaper::Generators::Fy2026::EnrollmentFilters::ExitDestinationFilter.all_destinations.map(&:label)

      outcome_sum = outcome_labels.sum { |label| rows.fetch(label).to_i }
      expect(outcome_sum).to eq(total_served)
    end
  end

  describe 'Longevity (Frequency) reporting edge cases' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:client) { create(:hud_client, data_source: data_source) }
    let!(:enrollment) do
      e = create_hiv_positive_enrollment(
        client: client,
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household_id,
      )
      # Must have a service in the period to be "served"
      create(:hud_service, enrollment: e, record_type: hopwa_financial_assistance,
                           type_provided: rental_assistance, fa_amount: 100,
                           date_provided: e.entry_date, data_source: data_source)
      e
    end

    def run_longevity
      _, rows = run_and_extract_rows([project], 'Q3')
      {
        first_time: rows.fetch('How many households have been served by STRMU for the first time this year?'),
        previous: rows.fetch('How many households also received STRMU assistance during the previous STRMU eligibility period?'),
        more_than_twice: rows.fetch('How many households received STRMU assistance more than twice during the previous five eligibility periods?'),
        consecutive: rows.fetch('How many households received STRMU assistance during the last five consecutive eligibility periods?'),
        total: rows.fetch('Longevity for Households Served by this Activity'),
      }
    end

    it 'ignores prior enrollments from other HOPWA activities (Funder Isolation)' do
      # Create a TBRA project and a prior enrollment in it
      tbra_funder = HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)')
      tbra_project = create_hopwa_project(funder: tbra_funder)
      create_hiv_positive_enrollment(
        client: client,
        project: tbra_project,
        entry_date: report_start_date - 1.year,
        household_id: Hmis::Hud::Base.generate_uuid,
      )

      results = run_longevity
      expect(results[:first_time]).to eq(1)
      expect(results[:previous]).to eq(0)
    end

    it 'excludes enrollments from 6+ years ago (Five-year window cutoff)' do
      create_hiv_positive_enrollment(
        client: client,
        project: project,
        entry_date: report_end_date - 6.years,
        household_id: Hmis::Hud::Base.generate_uuid,
      )

      results = run_longevity
      expect(results[:first_time]).to eq(1)
      expect(results[:more_than_twice]).to eq(0)
    end

    it 'deduplicates multiple enrollments in the same year' do
      # 2 prior enrollments in the same year (2 years ago)
      # 1 current enrollment
      # Total distinct years = 2. Should be "previous_year"
      [730, 740].each do |days_ago|
        create_hiv_positive_enrollment(
          client: client,
          project: project,
          entry_date: report_start_date - days_ago.days,
          household_id: Hmis::Hud::Base.generate_uuid,
        )
      end

      results = run_longevity
      expect(results[:previous]).to eq(1)
      expect(results[:more_than_twice]).to eq(0)
    end

    it 'correctly handles the boundary between "more than twice" and "consecutive" (4 vs 5 years)' do
      # Set current enrollment to 2026 to ensure we have room for 5 years back to 2022
      enrollment.update!(entry_date: report_end_date)

      # 4 distinct years (including current) -> more_than_twice
      # years: 2026 (current), 2025, 2024, 2023
      (1..3).each do |years_ago|
        create_hiv_positive_enrollment(
          client: client,
          project: project,
          entry_date: report_end_date - years_ago.years,
          household_id: Hmis::Hud::Base.generate_uuid,
        )
      end
      results = run_longevity
      expect(results[:more_than_twice]).to eq(1)
      expect(results[:consecutive]).to eq(0)

      # Add one more year (total 5) -> consecutive
      # years: 2026, 2025, 2024, 2023, 2022
      create_hiv_positive_enrollment(
        client: client,
        project: project,
        entry_date: report_end_date - 4.years,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
      results = run_longevity
      expect(results[:more_than_twice]).to eq(0)
      expect(results[:consecutive]).to eq(1)
    end

    it 'excludes enrollments exactly 5 years and 1 day before report_end_date' do
      # Window is (end_date - 5.years)..end_date
      # Let's say report_end_date is 2026-09-30
      # 5 years ago is 2021-09-30
      # 5 years and 1 day ago is 2021-09-29
      outside_window = report_end_date - 5.years - 1.day

      # Client is served this year (already created in 'enrollment')

      # Add an enrollment exactly 5 years and 1 day ago
      create_hiv_positive_enrollment(
        client: client,
        project: project,
        entry_date: outside_window,
        household_id: Hmis::Hud::Base.generate_uuid,
      )

      results = run_longevity
      # Total count should be 1 (the current enrollment)
      expect(results[:total]).to eq(1)
      # Should be "first_time" because the other enrollment is outside the window
      expect(results[:first_time]).to eq(1)
      expect(results[:previous]).to eq(0)
    end

    it 'includes enrollments exactly 5 years before report_end_date' do
      # Exactly 5 years ago is inside the window
      inside_window = report_end_date - 5.years

      # Client is served this year (already created in 'enrollment')

      # Add an enrollment exactly 5 years ago
      create_hiv_positive_enrollment(
        client: client,
        project: project,
        entry_date: inside_window,
        household_id: Hmis::Hud::Base.generate_uuid,
      )

      results = run_longevity
      expect(results[:total]).to eq(1)
      # Should be "previous" because we have 2 distinct years in the window (this year and 5 years ago)
      expect(results[:first_time]).to eq(0)
      expect(results[:previous]).to eq(1)
    end

    it 'deduplicates multiple enrollments in the same calendar year for frequency count' do
      # 2026: enrollment
      # 2025: two enrollments
      # Total distinct years = 2
      [365, 370].each do |days_ago|
        create_hiv_positive_enrollment(
          client: client,
          project: project,
          entry_date: report_end_date - days_ago.days,
          household_id: Hmis::Hud::Base.generate_uuid,
        )
      end

      results = run_longevity
      # Should be "previous_year" (<= 2 distinct years)
      expect(results[:previous]).to eq(1)
      expect(results[:more_than_twice]).to eq(0)
    end

    it 'verifies mutual exclusivity with mixed clients' do
      # 1. First time client (already created as 'enrollment')

      # 2. Previous year client
      client2 = create(:hud_client, data_source: data_source)
      e2 = create_hiv_positive_enrollment(client: client2, project: project, entry_date: report_start_date + 2.days, household_id: Hmis::Hud::Base.generate_uuid)
      create(:hud_service, enrollment: e2, record_type: hopwa_financial_assistance, type_provided: rental_assistance, fa_amount: 100, date_provided: e2.entry_date, data_source: data_source)
      create_hiv_positive_enrollment(client: client2, project: project, entry_date: report_start_date - 1.year, household_id: Hmis::Hud::Base.generate_uuid)

      # 3. More than twice client (3 years total)
      client3 = create(:hud_client, data_source: data_source)
      e3 = create_hiv_positive_enrollment(client: client3, project: project, entry_date: report_start_date + 3.days, household_id: Hmis::Hud::Base.generate_uuid)
      create(:hud_service, enrollment: e3, record_type: hopwa_financial_assistance, type_provided: rental_assistance, fa_amount: 100, date_provided: e3.entry_date, data_source: data_source)
      [1, 2].each do |years_ago|
        create_hiv_positive_enrollment(client: client3, project: project, entry_date: report_start_date - years_ago.years, household_id: Hmis::Hud::Base.generate_uuid)
      end

      # 4. Consecutive client (5 years total)
      client4 = create(:hud_client, data_source: data_source)
      e4 = create_hiv_positive_enrollment(client: client4, project: project, entry_date: report_end_date, household_id: Hmis::Hud::Base.generate_uuid)
      create(:hud_service, enrollment: e4, record_type: hopwa_financial_assistance, type_provided: rental_assistance, fa_amount: 100, date_provided: e4.entry_date, data_source: data_source)
      [1, 2, 3, 4].each do |years_ago|
        create_hiv_positive_enrollment(client: client4, project: project, entry_date: report_end_date - years_ago.years, household_id: Hmis::Hud::Base.generate_uuid)
      end

      results = run_longevity
      expect(results[:first_time]).to eq(1)
      expect(results[:previous]).to eq(1)
      expect(results[:more_than_twice]).to eq(1)
      expect(results[:consecutive]).to eq(1)
      expect(results[:total]).to eq(4)
    end
  end
end
