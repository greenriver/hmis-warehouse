# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

require_relative 'hopwa_caper_shared_context'
require_relative 'hopwa_caper_fbh_shared_context'

RSpec.describe HopwaCaper::Generators::Fy2026::Sheets::PFbhSheet, type: :model do
  include_context('FBH sheet shared context')

  let(:funder) do
    HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Permanent Housing (facility based or TBRA)')
  end

  let(:activity_label) { 'Permanent' }
  let(:activity_label_long) { 'permanent facility-based housing' }

  it 'reports facility information correctly' do
    _, rows = run_and_extract_rows([project], 'Q10')

    expect(rows.fetch('What is the name of the housing facility?')).to eq(project.project_name)
    expect(rows.fetch('Is the facility a medically assisted living facility? Yes or No.')).to eq('Yes')
    expect(rows.fetch('Was the housing facility placed into service during this program year? Yes or No.')).to eq('Yes')
    expect(rows.fetch('For housing facilities placed into service during this program year, how many units were placed into service? [Do not complete if facility placed in service in prior years.]').to_f).to eq(5.0)
  end

  it 'reports leasing support correctly' do
    _, rows = run_and_extract_rows([project], 'Q10')
    expect(rows.fetch("How many households received #{activity_label} Facility-Based Housing Leasing support for each facility?")).to eq(1)
    expect(rows.fetch("What were the HOPWA funds expended for #{activity_label} Facility-Based Housing Leasing Costs for each facility?")).to eq(0)
  end

  context 'with funder daily rate configured' do
    let(:daily_rate_key) { 'funder_daily_rate' }

    let!(:daily_rate_definition) do
      create(
        :hmis_custom_data_element_definition,
        key: daily_rate_key,
        owner_type: 'Hmis::Hud::Funder',
        field_type: :integer,
        data_source: data_source,
      )
    end

    before do
      config = instance_double(
        HopwaCaper::Configuration,
        atc_tab_enabled?: false,
        atc_maintained_contact_field_name: nil,
        atc_housing_plan_field_name: nil,
        atc_primary_health_contact_field_name: nil,
        funder_daily_rate_field_name: daily_rate_key,
      )
      allow(HopwaCaper::Configuration).to receive(:new).and_return(config)

      hud_funder = project.funders.first
      hud_funder.update!(start_date: report_start_date, end_date: report_end_date)
      hmis_funder = Hmis::Hud::Funder.find(hud_funder.id)
      create(
        :hmis_custom_data_element,
        data_element_definition: daily_rate_definition,
        owner: hmis_funder,
        value_integer: 10,
        data_source: data_source,
      )
    end

    it 'computes total_project_cost based on enrollment duration and daily rate' do
      report = create_report([project])
      run_report(report)

      # hoh_enrollment: entry at report_start_date + 1.day, no exit
      hoh_record = report.hopwa_caper_enrollments.find_by(enrollment_id: hoh_enrollment.id)
      hoh_days = (report_end_date - report_start_date).to_i
      expect(hoh_record.total_project_cost).to eq(hoh_days * 10)

      # exiting_enrollment: entry at report_start_date + 1.day, exit at report_start_date + 2.months
      exiting_record = report.hopwa_caper_enrollments.find_by(enrollment_id: exiting_enrollment.id)
      exit_date = report_start_date + 2.months
      exiting_days = (exit_date - 1.day - report_start_date).to_i
      expect(exiting_record.total_project_cost).to eq(exiting_days * 10)
    end

    it 'reports leasing expenditure totals per facility' do
      _, rows = run_and_extract_rows([project], 'Q10')

      hoh_days = (report_end_date - report_start_date).to_i
      exit_date = report_start_date + 2.months
      exiting_days = (exit_date - 1.day - report_start_date).to_i
      expected_total = (hoh_days + exiting_days) * 10

      expect(rows.fetch("What were the HOPWA funds expended for #{activity_label} Facility-Based Housing Leasing Costs for each facility?")).to eq(expected_total)
    end

    it 'uses the higher rate when funders overlap' do
      # Add a second funder active only for the first 3 months at a higher rate
      second_funder = create(
        :hud_funder,
        project: project,
        ProjectID: project.ProjectID,
        funder: funder,
        data_source: data_source,
        start_date: report_start_date,
        end_date: report_start_date + 3.months,
      )
      hmis_second_funder = Hmis::Hud::Funder.find(second_funder.id)
      create(
        :hmis_custom_data_element,
        data_element_definition: daily_rate_definition,
        owner: hmis_second_funder,
        value_integer: 25,
        data_source: data_source,
      )

      report = create_report([project])
      run_report(report)

      # hoh_enrollment: entry at report_start_date + 1.day, no exit
      # Days in the overlap period get the higher rate (25), remaining days get 10
      overlap_end = report_start_date + 3.months
      high_rate_days = (overlap_end - (report_start_date + 1.day)).to_i + 1
      low_rate_days = (report_end_date - overlap_end).to_i
      expected = (high_rate_days * 25) + (low_rate_days * 10)

      hoh_record = report.hopwa_caper_enrollments.find_by(enrollment_id: hoh_enrollment.id)
      expect(hoh_record.total_project_cost).to eq(expected)
    end

    it 'limits costs to the funder active period when it partially covers the report' do
      # Narrow the existing funder to only the last 2 months of the report
      funder_start = report_end_date - 2.months
      project.funders.first.update!(start_date: funder_start, end_date: report_end_date)

      report = create_report([project])
      run_report(report)

      # hoh_enrollment: entry at report_start_date + 1.day, no exit
      # Cost only accrues during the funder's active window
      hoh_record = report.hopwa_caper_enrollments.find_by(enrollment_id: hoh_enrollment.id)
      expected_days = (report_end_date - funder_start).to_i + 1
      expect(hoh_record.total_project_cost).to eq(expected_days * 10)

      # exiting_enrollment: exits at report_start_date + 2.months, well before funder becomes active
      exiting_record = report.hopwa_caper_enrollments.find_by(enrollment_id: exiting_enrollment.id)
      expect(exiting_record.total_project_cost).to eq(0)
    end

    it 'assigns zero cost to non-head-of-household members' do
      non_hoh_client = create(:hud_client, data_source: data_source)
      create_hiv_positive_enrollment(
        client: non_hoh_client,
        project: project,
        entry_date: report_start_date + 1.day,
        household_id: household_id,
        relationship_to_ho_h: 2,
      )

      report = create_report([project])
      run_report(report)

      non_hoh_record = report.hopwa_caper_enrollments.find_by(
        destination_client_id: GrdaWarehouse::Hud::Client.find(non_hoh_client.id).destination_client.id,
        relationship_to_hoh: 2,
      )
      expect(non_hoh_record.total_project_cost).to eq(0)
    end
  end

  it 'reports income and insurance correctly' do
    _, rows = run_and_extract_rows([project], 'Q10')
    expect(rows.fetch('Earned Income from Employment')).to eq(1)
    expect(rows.fetch('MEDICAID Health Program or local program equivalent')).to eq(1)
  end

  it 'includes no-income households in the income sources total' do
    no_income_client = create(:hud_client, data_source: data_source)
    no_income_enrollment = create_hiv_positive_enrollment(
      client: no_income_client,
      project: project,
      entry_date: report_start_date + 1.day,
      household_id: Hmis::Hud::Base.generate_uuid,
    )
    create(
      :hud_income_benefit,
      enrollment: no_income_enrollment,
      information_date: report_start_date + 1.day,
      IncomeFromAnySource: 0,
      data_source: data_source,
    )

    _, rows = run_and_extract_rows([project], 'Q10')
    expect(rows.fetch('How many households maintained no sources of income?')).to eq(1)
    # Total should include households with income (hoh_client) AND without (no_income_client)
    expect(rows.fetch('How many households accessed or maintained access to the following sources of income in the past year?')).to eq(2)
  end

  it 'renders a placeholder column when no facility-based projects are in scope' do
    non_facility_project = create_hopwa_project(funder: funder).tap { |p| p.update!(HousingType: 3) }
    _, rows = run_and_extract_rows([non_facility_project], 'Q10')
    expect(rows.fetch('What is the name of the housing facility?')).to eq('No facilities in scope')
    expect(rows.fetch('Was the housing facility placed into service during this program year? Yes or No.')).to eq('No')
  end

  it 'reports housing outcomes correctly' do
    _, rows = run_and_extract_rows([project], 'Q10')
    expect(rows.fetch('How many households exited to private housing?')).to eq(1)
  end

  it 'reports longevity correctly' do
    _, rows = run_and_extract_rows([project], 'Q10')
    # hoh_client has prior_enrollment 2+ years old -> "1-5 years" bucket
    expect(rows.fetch("How many households have been served with #{activity_label_long} for more than one year, but less than five years?")).to eq(1)
    # exiting_client enrolled this year -> "less than one year" bucket
    expect(rows.fetch("How many households have been served with #{activity_label_long} for less than one year?")).to eq(1)
  end

  it 'reports health outcomes correctly' do
    _, rows = run_and_extract_rows([project], 'Q10')
    expect(rows.fetch('How many HOPWA-eligible individuals served with PFBH this year have ever been prescribed Anti-Retroviral Therapy, by facility?')).to eq(2)
  end

  it 'deduplicates households correctly' do
    # Add another member to the same household
    other_member = create(:hud_client, data_source: data_source)
    create_hiv_positive_enrollment(
      client: other_member,
      project: project,
      entry_date: report_start_date + 1.day,
      household_id: household_id,
      relationship_to_ho_h: 2,
    )

    _, rows = run_and_extract_rows([project], 'Q10')
    # Total Deduplicated Household Count should be 2 (hoh_client and exiting_client), not 3 (including other_member)
    expect(rows.fetch('Total Deduplicated Household Count')).to eq(2)
  end

  it 'correctly attributes data to multiple facilities' do
    # Create a second project/facility
    project2 = create_hopwa_project(funder: funder).tap do |p|
      p.update!(HousingType: 1, project_name: 'Second Facility')
    end

    # Enroll a DIFFERENT client in project2
    client2 = create(:hud_client, data_source: data_source)
    create_hiv_positive_enrollment(
      client: client2,
      project: project2,
      entry_date: report_start_date + 1.day,
      household_id: Hmis::Hud::Base.generate_uuid,
    )

    _, rows = run_and_extract_fbh_rows([project, project2], 'Q10')

    # Names should match their columns
    expect(rows.fetch('What is the name of the housing facility?')).to eq([project.project_name, project2.project_name])

    # Counts should be isolated per facility
    # Project 1 has 2 households (hoh_client and exiting_client)
    # Project 2 has 1 household (client2)
    expect(rows.fetch('Total Deduplicated Household Count')).to eq([2, 1])
  end
end
