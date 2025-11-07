###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'

RSpec.describe 'HOPWA CAPER Housing Information Services', type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)')
  end

  let(:project) do
    create_hopwa_project(funder: funder)
  end

  let(:housing_info_category_name) do
    HopwaCaper::Generators::Fy2026::Sheets::HousingInfoSheet::HOUSING_INFO_CATEGORY_NAME
  end

  let(:custom_service_category) do
    create(:hmis_custom_service_category, data_source: data_source, name: housing_info_category_name)
  end

  let(:custom_service_type) do
    create(:hmis_custom_service_type, data_source: data_source, custom_service_category: custom_service_category)
  end

  context 'with a household that received housing information services' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:hoh_enrollment) do
      create_enrollment(
        client: create(:hud_client, data_source: data_source),
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

    let!(:housing_info_service) do
      Hmis::Hud::CustomService.insert_all([
        {
          'CustomServiceID' => SecureRandom.uuid.delete('-'),
          'EnrollmentID' => hoh_enrollment.EnrollmentID,
          'PersonalID' => hoh_enrollment.client.PersonalID,
          'UserID' => SecureRandom.uuid.delete('-'),
          'DateProvided' => report_start_date + 10.days,
          data_source_id: hoh_enrollment.data_source_id,
          custom_service_type_id: custom_service_type.id,
          'DateCreated' => Time.current,
          'DateUpdated' => Time.current,
        },
      ])
    end

    it 'reports households served for housing information services' do
      report = create_report([project])
      run_report(report)

      rows = question_as_rows(question_number: 'Q5', report: report).to_h

      expect(rows.fetch('How many households were served with housing information services?')).to eq(1)
      expect(rows.fetch('What were the HOPWA funds expended for Housing Information Services?')).to be_blank
    end
  end
end
