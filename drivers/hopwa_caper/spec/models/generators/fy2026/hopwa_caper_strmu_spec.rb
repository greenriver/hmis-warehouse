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

    it 'only counts households with services in the reporting period' do
      _, rows = run_and_extract_rows([project], 'Q3')

      # Only the household with services in the period should be counted
      expect(rows.fetch('STRMU Households Total')).to eq(1)
      expect(rows.fetch('How many households were served with STRMU rental assistance only?')).to eq(1)

      # The household without services should NOT be in "more than one type"
      expect(rows.fetch('How many households received more than one type of STRMU assistance?')).to eq(0)
    end
  end
end
