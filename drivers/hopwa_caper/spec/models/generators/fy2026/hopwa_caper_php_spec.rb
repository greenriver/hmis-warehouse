###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
RSpec.describe 'HOPWA CAPER PHP', type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing Placement')
  end

  let(:project) do
    create_hopwa_project(funder: funder)
  end

  context 'with one multi-member household' do
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
      ).tap do |enrollment|
        create(
          :hud_disability,
          disability_type: hiv_positive,
          enrollment: enrollment,
          anti_retroviral: 1,
          viral_load_available: 1,
          viral_load: 100,
          data_source: data_source,
        )
      end
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

    it 'reports household count, medical insurance, and income sources' do
      hoh_enrollment.income_benefits.create!(Medicaid: 1, Earned: 1, information_date: report_start_date)
      report = create_report([project])
      run_report(report)
      rows = question_as_rows(question_number: 'Q4', report: report).to_h
      expect(rows.fetch('How many households were served with PHP assistance?')).to eq(1)
      expect(rows.fetch('Earned Income from Employment')).to eq(1)
      expect(rows.fetch('MEDICAID Health Program or local program equivalent')).to eq(1)
    end
  end

  context 'with multiple households and housing outcomes' do
    let(:household1_id) { Hmis::Hud::Base.generate_uuid }
    let(:household2_id) { Hmis::Hud::Base.generate_uuid }

    let!(:hoh1_enrollment) do
      create_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household1_id,
        relationship_to_ho_h: 1,
      ).tap do |enrollment|
        create(
          :hud_disability,
          disability_type: hiv_positive,
          enrollment: enrollment,
          anti_retroviral: 1,
          viral_load_available: 1,
          viral_load: 100,
          data_source: data_source,
        )
      end
    end

    let!(:hoh2_enrollment) do
      create_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 2.days,
        household_id: household2_id,
        relationship_to_ho_h: 1,
      ).tap do |enrollment|
        create(
          :hud_disability,
          disability_type: hiv_positive,
          enrollment: enrollment,
          anti_retroviral: 1,
          viral_load_available: 1,
          viral_load: 100,
          data_source: data_source,
        )
      end
    end

    let(:exit_to_other_hopwa_code) do
      HudHelper.util('2026').destinations.invert.fetch('Moved from one HOPWA funded project to HOPWA PH')
    end

    let(:exit_to_private_housing_code) do
      HudHelper.util('2026').destinations.invert.fetch('Rental by client, no ongoing housing subsidy')
    end

    before do
      create(
        :hud_exit,
        enrollment: hoh1_enrollment,
        exit_date: report_end_date - 10.days,
        destination: exit_to_other_hopwa_code,
        data_source: data_source,
      )
      create(
        :hud_exit,
        enrollment: hoh2_enrollment,
        exit_date: report_end_date - 5.days,
        destination: exit_to_private_housing_code,
        data_source: data_source,
      )
    end

    it 'counts households by exit destination' do
      report = create_report([project])
      run_report(report)
      rows = question_as_rows(question_number: 'Q4', report: report).to_h

      expect(rows.fetch('How many households were served with PHP assistance?')).to eq(2)
      expect(rows.fetch('How many households exited to other HOPWA housing programs?')).to eq(1)
      expect(rows.fetch('How many households exited to private housing?')).to eq(1)
    end
  end
end
