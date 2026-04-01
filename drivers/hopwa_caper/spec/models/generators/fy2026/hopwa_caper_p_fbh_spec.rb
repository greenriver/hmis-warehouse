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
    # leasing costs aren't reported
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
