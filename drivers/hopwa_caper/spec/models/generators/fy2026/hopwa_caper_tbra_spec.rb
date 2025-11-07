###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
RSpec.describe 'HOPWA CAPER TBRA', type: :model do
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

    it 'reports household count, medical insurance, and income_benefit' do
      hoh_enrollment.income_benefits.create!(Medicaid: 1, Earned: 1, information_date: report_start_date)
      report = create_report([project])
      run_report(report)
      rows = question_as_rows(question_number: 'Q2', report: report).to_h
      expect(rows.fetch('How many households were served with HOPWA TBRA assistance?')).to eq(1)
      expect(rows.fetch('Earned Income from Employment')).to eq(1)
      expect(rows.fetch('MEDICAID Health Program or local program equivalent')).to eq(1)
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
        report = create_report([project])
        run_report(report)
        rows = question_as_rows(question_number: 'Q2', report: report).to_h
        expect(rows.fetch('How many households have been served with TBRA for less than one year?')).to eq(0)
        expect(rows.fetch('How many households have been served with TBRA for more than one year, but less than five years?')).to eq(1)
      end
    end
  end
end
