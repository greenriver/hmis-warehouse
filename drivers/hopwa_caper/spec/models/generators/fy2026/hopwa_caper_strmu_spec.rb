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
      expect(rows.fetch('How many households have been served by STRMU for the first time this year?')).to eq(1)
    end

    context 'with a prior enrollments' do
      before do
        previous_enrollment = create_enrollment(
          client: hoh_client,
          project: project,
          entry_date: report_start_date - 1.year,
          household_id: Hmis::Hud::Base.generate_uuid,
          relationship_to_ho_h: 1,
        )
        create(
          :hud_exit,
          enrollment: previous_enrollment,
          exit_date: previous_enrollment.entry_date,
          data_source: data_source,
        )
      end

      it 'counts longevity' do
        _, rows = run_and_extract_rows([project], 'Q3')
        expect(rows.fetch('How many households have been served by STRMU for the first time this year?')).to eq(0)
        expect(rows.fetch('How many households also received STRMU assistance during the previous year?')).to eq(1)
      end
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

      # Household 2: receives only utilities assistance (single type)
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

    it 'correctly categorizes households by assistance type' do
      _, rows = run_and_extract_rows([project], 'Q3')

      expect(rows.fetch('STRMU Households Total')).to eq(2)
      expect(rows.fetch('How many households were served with STRMU utilities assistance only?')).to eq(1)
      expect(rows.fetch('How many households received more than one type of STRMU assistance?')).to eq(1)
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

      # They should NOT be in "mortgage assistance only" or "utilities assistance only"
      expect(rows.fetch('How many households were served with STRMU mortgage assistance only?')).to eq(0)
      # (household2 is still utilities only)
      expect(rows.fetch('How many households were served with STRMU utilities assistance only?')).to eq(1)
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
        'How many households also received STRMU assistance during the previous year?',
        'How many households received STRMU assistance more than twice during the previous five years?',
        'How many households received STRMU assistance during the last five consecutive years?',
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
end
