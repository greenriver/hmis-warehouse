# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'

RSpec.describe HopwaCaper::Generators::Fy2026::Sheets::SupportiveServicesSheet, type: :model do
  include_context('HOPWA CAPER shared context')

  let(:funder) do
    HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)')
  end

  let(:project) do
    create_hopwa_project(funder: funder)
  end

  let(:case_management_code) { supportive_service_types.invert.fetch('Case management') }
  let(:substance_use_code) { supportive_service_types.invert.fetch('Substance use services/treatment') }
  let(:transportation_code) { supportive_service_types.invert.fetch('Transportation') }

  context 'with multiple households receiving supportive services' do
    let(:household_with_multiple_services) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
    end

    let(:secondary_household) do
      create_hiv_positive_enrollment(
        client: create(:hud_client, data_source: data_source),
        project: project,
        entry_date: report_start_date + 2.days,
        household_id: Hmis::Hud::Base.generate_uuid,
      )
    end

    before do
      create(
        :hud_service,
        record_type: hopwa_supportive_service,
        enrollment: household_with_multiple_services,
        type_provided: case_management_code,
        fa_amount: 120,
        date_provided: household_with_multiple_services.entry_date,
        data_source: data_source,
      )

      create(
        :hud_service,
        record_type: hopwa_supportive_service,
        enrollment: household_with_multiple_services,
        type_provided: substance_use_code,
        fa_amount: 80,
        date_provided: household_with_multiple_services.entry_date,
        data_source: data_source,
      )

      create(
        :hud_service,
        record_type: hopwa_supportive_service,
        enrollment: secondary_household,
        type_provided: transportation_code,
        fa_amount: 15,
        date_provided: secondary_household.entry_date,
        data_source: data_source,
      )
    end

    it 'reports households and expenditures by supportive service type with deduplicated totals' do
      report = create_report([project])
      run_report(report)
      rows = question_as_rows(question_number: 'Q6', report: report)
      indexed = rows.to_h { |row| [row[0], row[1..]] }

      case_management = indexed.fetch('Case Management')
      expect(case_management.first).to eq(1)
      expect(case_management.last).to be_blank

      substance_use = indexed.fetch('Alcohol-Drug Abuse')
      expect(substance_use.first).to eq(1)
      expect(substance_use.last).to be_blank

      transportation = indexed.fetch('Transportation')
      expect(transportation.first).to eq(1)
      expect(transportation.last).to be_blank
      expect(indexed.fetch('How many households received more than one type of Supportive Services?').first).to eq(1)
      expect(indexed.fetch('Deduplicated Supportive Services Household Total (based on amounts reported in Rows 5-21 above)').first).to eq(2)

      # Verify HUD service metadata is populated
      expect(report.hopwa_caper_services.count).to eq(3)
      case_mgmt_service = report.hopwa_caper_services.find_by(type_provided: case_management_code)
      expect(case_mgmt_service.service_source).to eq(HopwaCaper::Service::HUD_SERVICE_SOURCE)
      expect(case_mgmt_service.service_category_name).to eq('HOPWA Service')
      expect(case_mgmt_service.service_type_name).to eq('Case management')
    end

    context 'with legacy supportive services before the reporting period' do
      let(:legacy_service_date) { (report_start_date - 10.years).to_date }

      before do
        create(
          :hud_service,
          record_type: hopwa_supportive_service,
          enrollment: household_with_multiple_services,
          type_provided: case_management_code,
          fa_amount: 60,
          date_provided: legacy_service_date,
          data_source: data_source,
        )
      end

      it 'captures historical services for lookback analysis without affecting current year totals' do
        report = create_report([project])
        run_report(report)

        expect(
          report.hopwa_caper_services.hud_services.where(date_provided: legacy_service_date).count,
        ).to eq(1)

        rows = question_as_rows(question_number: 'Q6', report: report)
        indexed = rows.to_h { |row| [row[0], row[1..]] }

        expect(indexed.fetch('Case Management').first).to eq(1)
      end
    end
  end

  context 'with percent AMI values for drilldown display' do
    let!(:setup) do
      create_enrolled_client_with_service(
        client_attrs: {
          DOB: today - 40.years,
          DOBDataQuality: 1,
          White: 1,
          Sex: 1,
        },
        project: project,
        entry_date: report_start_date + 1.day,
        service_type: hopwa_supportive_service,
        type_provided: case_management_code,
      )
    end

    it 'transforms percent_ami and sex to human-readable strings in drilldowns' do
      report = create_report([project])
      run_report(report)

      expect(report.hopwa_caper_enrollments.size).to eq(1)
      enrollment = report.hopwa_caper_enrollments.first

      # Test display_value transforms percent_ami codes correctly
      expect(enrollment.display_value('percent_ami', pii_policy: nil, cell_val: 1, calculate_cell: false)).to eq('30% or less')
      expect(enrollment.display_value('percent_ami', pii_policy: nil, cell_val: 2, calculate_cell: false)).to eq('31% to 50%')
      expect(enrollment.display_value('percent_ami', pii_policy: nil, cell_val: 3, calculate_cell: false)).to eq('51% to 80%')
      expect(enrollment.display_value('percent_ami', pii_policy: nil, cell_val: 4, calculate_cell: false)).to eq('81% or greater')
      expect(enrollment.display_value('percent_ami', pii_policy: nil, cell_val: 99, calculate_cell: false)).to eq('Data not collected')

      # Test display_value transforms sex codes correctly
      expect(enrollment.display_value('sex', pii_policy: nil, cell_val: 0, calculate_cell: false)).to eq('Female')
      expect(enrollment.display_value('sex', pii_policy: nil, cell_val: 1, calculate_cell: false)).to eq('Male')
      expect(enrollment.display_value('sex', pii_policy: nil, cell_val: 99, calculate_cell: false)).to eq('Data not collected')

      # Test nil handling
      expect(enrollment.display_value('sex', pii_policy: nil, cell_val: nil, calculate_cell: false)).to be_nil
      expect(enrollment.display_value('percent_ami', pii_policy: nil, cell_val: nil, calculate_cell: false)).to be_nil
    end
  end
end
