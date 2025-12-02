# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'

RSpec.describe HopwaCaper::Generators::Fy2026::Sheets::HousingInfoSheet, type: :model do
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
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household_id,
      )
    end

    let!(:housing_info_service) do
      Hmis::Hud::CustomService.insert_all(
        [
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
        ],
      )
    end

    it 'reports households served for housing information services' do
      report, rows = run_and_extract_rows([project], 'Q5')

      expect(rows.fetch('How many households were served with housing information services?')).to eq(1)
      expect(report.hopwa_caper_services.count).to eq(1)
      expect(report.hopwa_caper_services.first.service_source).to eq(HopwaCaper::Service::CUSTOM_SERVICE_SOURCE)
      expect(report.hopwa_caper_services.first.service_category_name).to eq(housing_info_category_name)
      expect(report.hopwa_caper_services.first.service_type_name).to eq(custom_service_type.name)
    end
  end

  context 'with housing information services prior to the reporting period' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:legacy_service_date) { (report_start_date - 10.years).to_date }
    let(:hoh_enrollment) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: legacy_service_date,
        household_id: household_id,
      )
    end

    let!(:legacy_housing_info_service) do
      Hmis::Hud::CustomService.insert_all(
        [
          {
            'CustomServiceID' => SecureRandom.uuid.delete('-'),
            'EnrollmentID' => hoh_enrollment.EnrollmentID,
            'PersonalID' => hoh_enrollment.client.PersonalID,
            'UserID' => SecureRandom.uuid.delete('-'),
            'DateProvided' => legacy_service_date,
            data_source_id: hoh_enrollment.data_source_id,
            custom_service_type_id: custom_service_type.id,
            'DateCreated' => Time.current,
            'DateUpdated' => Time.current,
          },
        ],
      )
    end

    it 'captures historical custom services without affecting current-period totals' do
      report, rows = run_and_extract_rows([project], 'Q5')

      expect(
        report.hopwa_caper_services.custom_services.where(date_provided: legacy_service_date).count,
      ).to eq(1)

      expect(rows.fetch('How many households were served with housing information services?')).to eq(0)
    end
  end

  context 'with multiple households receiving housing information services' do
    let(:household1_id) { Hmis::Hud::Base.generate_uuid }
    let(:household2_id) { Hmis::Hud::Base.generate_uuid }

    let(:hoh1_enrollment) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household1_id,
      )
    end

    let(:hoh2_enrollment) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 2.days,
        household_id: household2_id,
      )
    end

    let(:custom_service_category) do
      create(:hmis_custom_service_category, data_source: data_source, name: housing_info_category_name)
    end

    let(:custom_service_type) do
      create(:hmis_custom_service_type, data_source: data_source, custom_service_category: custom_service_category)
    end

    before do
      [hoh1_enrollment, hoh2_enrollment].each do |enrollment|
        Hmis::Hud::CustomService.insert_all(
          [
            {
              'CustomServiceID' => SecureRandom.uuid.delete('-'),
              'EnrollmentID' => enrollment.EnrollmentID,
              'PersonalID' => enrollment.client.PersonalID,
              'UserID' => SecureRandom.uuid.delete('-'),
              'DateProvided' => report_start_date + 10.days,
              data_source_id: enrollment.data_source_id,
              custom_service_type_id: custom_service_type.id,
              'DateCreated' => Time.current,
              'DateUpdated' => Time.current,
            },
          ],
        )
      end
    end

    it 'counts all households receiving housing information services' do
      report, rows = run_and_extract_rows([project], 'Q5')

      expect(rows.fetch('How many households were served with housing information services?')).to eq(2)
      expect(report.hopwa_caper_services.count).to eq(2)
    end
  end

  context 'with services outside report date range' do
    let(:household_id) { Hmis::Hud::Base.generate_uuid }
    let(:hoh_enrollment) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date - 30.days,
        household_id: household_id,
      )
    end

    let(:custom_service_category) do
      create(:hmis_custom_service_category, data_source: data_source, name: housing_info_category_name)
    end

    let(:custom_service_type) do
      create(:hmis_custom_service_type, data_source: data_source, custom_service_category: custom_service_category)
    end

    let!(:service_before_range) do
      Hmis::Hud::CustomService.insert_all(
        [
          {
            'CustomServiceID' => SecureRandom.uuid.delete('-'),
            'EnrollmentID' => hoh_enrollment.EnrollmentID,
            'PersonalID' => hoh_enrollment.client.PersonalID,
            'UserID' => SecureRandom.uuid.delete('-'),
            'DateProvided' => report_start_date - 1.day,
            data_source_id: hoh_enrollment.data_source_id,
            custom_service_type_id: custom_service_type.id,
            'DateCreated' => Time.current,
            'DateUpdated' => Time.current,
          },
        ],
      )
    end

    let!(:service_after_range) do
      Hmis::Hud::CustomService.insert_all(
        [
          {
            'CustomServiceID' => SecureRandom.uuid.delete('-'),
            'EnrollmentID' => hoh_enrollment.EnrollmentID,
            'PersonalID' => hoh_enrollment.client.PersonalID,
            'UserID' => SecureRandom.uuid.delete('-'),
            'DateProvided' => report_end_date + 1.day,
            data_source_id: hoh_enrollment.data_source_id,
            custom_service_type_id: custom_service_type.id,
            'DateCreated' => Time.current,
            'DateUpdated' => Time.current,
          },
        ],
      )
    end

    it 'excludes services outside the report date range' do
      report, rows = run_and_extract_rows([project], 'Q5')

      expect(rows.fetch('How many households were served with housing information services?')).to eq(0)
      expect(report.hopwa_caper_services.count).to eq(1)
      expect(
        report.hopwa_caper_services.where(date_provided: report_start_date - 1.day).count,
      ).to eq(1)
    end
  end
end
