# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
RSpec.describe HopwaCaper::Generators::Fy2026::Sheets::TbraSheet, type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)')
  end

  let(:project) do
    create_hopwa_project(funder: funder)
  end

  context 'With one multi-member household served with rental assistance' do
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

    it 'reports household count, medical insurance, income sources, and health outcomes' do
      create_standard_income_benefits(hoh_enrollment)
      _, rows = run_and_extract_rows([project], 'Q2')
      expect(rows.fetch('How many households were served with HOPWA TBRA assistance?')).to eq(1)
      expect(rows.fetch('Earned Income from Employment')).to eq(1)
      expect(rows.fetch('MEDICAID Health Program or local program equivalent')).to eq(1)
      expect(rows.fetch('How many HOPWA-eligible individuals served with TBRA this year have ever been prescribed Anti-Retroviral Therapy?')).to eq(1)
      expect(rows.fetch('How many HOPWA-eligible persons served with TBRA have shown an improved viral load or achieved viral suppression?')).to eq(1)
      expect(rows.fetch('How many households have been served with TBRA for less than one year?')).to eq(1)
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
        _, rows = run_and_extract_rows([project], 'Q2')
        expect(rows.fetch('How many households have been served with TBRA for less than one year?')).to eq(0)
        expect(rows.fetch('How many households have been served with TBRA for more than one year, but less than five years?')).to eq(1)
      end
    end
  end

  context 'with various exit scenarios for continued assistance' do
    let!(:no_exit_enrollment) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 1.day,
        exit_date: nil,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
    end

    let!(:exit_after_report_enrollment) do
      enrollment = create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
      create(
        :hud_exit,
        enrollment: enrollment,
        exit_date: report_end_date + 30.days, # Exits AFTER report period
        data_source: data_source,
      )
      enrollment
    end

    let!(:exit_on_last_day_enrollment) do
      enrollment = create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
      create(
        :hud_exit,
        enrollment: enrollment,
        exit_date: report_end_date, # Exits ON last day of report
        data_source: data_source,
      )
      enrollment
    end

    let!(:exit_before_end_enrollment) do
      enrollment = create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
      create(
        :hud_exit,
        enrollment: enrollment,
        exit_date: report_end_date - 10.days, # Exits BEFORE end of report
        data_source: data_source,
      )
      enrollment
    end

    it 'counts households with no exit or exit after report period as continuing' do
      _, rows = run_and_extract_rows([project], 'Q2')

      # Should count:
      # - no_exit_enrollment (exit_date IS NULL)
      # - exit_after_report_enrollment (exit_date > report.end_date)
      # Should NOT count:
      # - exit_on_last_day_enrollment (exit_date = report.end_date)
      # - exit_before_end_enrollment (exit_date < report.end_date)
      expect(rows.fetch('How many households continued receiving this type of HOPWA assistance into the next year?')).to eq(2)
    end
  end
end
