# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
RSpec.describe HopwaCaper::Generators::Fy2026::Sheets::PhpSheet, type: :model do
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

    it 'reports household count, medical insurance, and income sources' do
      create_standard_income_benefits(hoh_enrollment)
      _, rows = run_and_extract_rows([project], 'Q4')
      expect(rows.fetch('How many households were served with PHP assistance?')).to eq(1)
      expect(rows.fetch('Earned Income from Employment')).to eq(1)
      expect(rows.fetch('MEDICAID Health Program or local program equivalent')).to eq(1)
    end
  end

  context 'with multiple households and housing outcomes' do
    let(:household1_id) { Hmis::Hud::Base.generate_uuid }
    let(:household2_id) { Hmis::Hud::Base.generate_uuid }

    let!(:hoh1_enrollment) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household1_id,
      )
    end

    let!(:hoh2_enrollment) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 2.days,
        household_id: household2_id,
      )
    end

    let(:exit_to_other_hopwa_code) do
      hud_code(:destinations, 'Moved from one HOPWA funded project to HOPWA PH')
    end

    let(:exit_to_private_housing_code) do
      hud_code(:destinations, 'Rental by client, no ongoing housing subsidy')
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
      _, rows = run_and_extract_rows([project], 'Q4')

      expect(rows.fetch('How many households were served with PHP assistance?')).to eq(2)
      expect(rows.fetch('How many households exited to other HOPWA housing programs?')).to eq(1)
      expect(rows.fetch('How many households exited to private housing?')).to eq(1)
    end
  end
end
