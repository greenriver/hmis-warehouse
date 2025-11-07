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

    it 'reports household count' do
      report = create_report([project])
      run_report(report)
      rows = question_as_rows(question_number: 'Q4', report: report).to_h
      expect(rows.fetch('How many households were served with PHP assistance?')).to eq(1)
    end
  end
end
