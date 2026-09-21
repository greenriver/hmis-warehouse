###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Contract spec for PublicReports::StateLevelHomelessness#chart_data (schema_version 2).
# This is the guard against a client-privacy redaction regression: everything below
# MIN_THRESHOLD (11) or the 100-person donut/breakdown floor must come back nil, never
# a raw small integer. Do not assert map rates or counts: overall_population_geography,
# homeless_population_overall and count_homeless_population all return random numbers
# outside production (see state_level_homelessness.rb), so the map's *shape* is checked,
# never its values.
RSpec.describe PublicReports::StateLevelHomelessness, type: :model do
  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }

  let(:source_data_source) { create(:data_source_fixed_id) }
  let(:destination_data_source) { create(:grda_warehouse_data_source) }
  let(:organization) { create(:hud_organization, data_source_id: source_data_source.id) }
  let(:project) { create(:hud_project, data_source_id: source_data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 1) }

  let(:report_start) { Date.parse('2025-01-01') }
  let(:report_end) { Date.parse('2025-12-31') }

  # Gender lives directly on the client SHE.client_id points at. Race is only
  # resolvable through a WarehouseClient link to a separate "source" client
  # (see Hud::Client's race_white/race_am_ind_ak_native/etc scopes, which
  # join WarehouseClient.source) -- so each of these builds both.
  def create_homeless_client_and_entry(gender:, race_field:, household_id:)
    dest_client = create(:hud_client, data_source_id: destination_data_source.id, gender => 1)
    race_source_client = create(:hud_client, data_source_id: source_data_source.id, race_field => 1)
    create(:warehouse_client, destination_id: dest_client.id, source_id: race_source_client.id, data_source_id: source_data_source.id)

    she = create(
      :she_entry,
      client: dest_client,
      data_source_id: source_data_source.id,
      project_id: project.project_id,
      organization_id: project.organization_id,
      project_type: 1,
      date: Date.parse('2025-10-15'),
      first_date_in_program: Date.parse('2025-10-15'),
      last_date_in_program: report_end,
      household_id: household_id,
    )
    [Date.parse('2025-10-15'), Date.parse('2025-11-15'), Date.parse('2025-12-15')].each do |date|
      create(
        :service_history_service,
        service_history_enrollment_id: she.id,
        client_id: dest_client.id,
        record_type: 'service',
        date: date,
        project_type: 1,
        age: 30,
      )
    end
  end

  # A handful of clients, spread across race/gender, all entered in the
  # report's final quarter -- small enough that every donut/breakdown total
  # should come back suppressed, which is exactly the case this spec exists
  # to guard.
  before do
    setup_access_control(user, role, Collection.system_collection(:data_sources))

    [
      { gender: :Woman, race_field: :White },
      { gender: :Man, race_field: :AmIndAKNative },
      { gender: :Woman, race_field: :BlackAfAmerican },
      { gender: :Man, race_field: :Asian },
      { gender: :Woman, race_field: :NativeHIPacific },
    ].each_with_index do |attrs, i|
      create_homeless_client_and_entry(household_id: "household-#{i}", **attrs)
    end
  end

  let(:report) do
    report = described_class.new(
      user: user,
      filter: { filters: { start: report_start, end: report_end, project_type_numbers: [1, 2, 8, 4] } },
    )
    report.save!
    report.run_and_save!
    report
  end

  let(:data) { report.parsed_pre_calculated_data }

  it 'has schema_version 2' do
    expect(data['schema_version']).to eq(2)
  end

  it 'sizes every per-period array to match periods' do
    periods_size = data['periods'].size
    who = data['who']
    map = data['map']

    who['donuts'].each_value do |donut|
      expect(donut['values'].size).to eq(periods_size)
      expect(donut['totals'].size).to eq(periods_size)
    end
    expect(who['race']['homeless'].size).to eq(periods_size)
    who['breakdown'].each_value do |row|
      expect(row['totals'].size).to eq(periods_size)
      expect(row['chronic'].size).to eq(periods_size)
      expect(row['unsheltered'].size).to eq(periods_size)
    end
    expect(map['values'].size).to eq(periods_size)
    expect(map['statewideTotals'].size).to eq(periods_size)
  end

  it 'suppresses a small group to nil totals and a nil sheltered array' do
    # 5 clients is under the 100-person donut floor and under MIN_THRESHOLD (11)
    # for sheltered/unsheltered on every breakdown row -- if suppression broke,
    # this would show a raw integer instead.
    all_people = data['who']['donuts']['all-people']
    expect(all_people['totals']).to all(satisfy { |t| t.nil? || t.zero? || t > 100 })
    expect(all_people['totals']).to include(nil)

    small_row = data['who']['breakdown'].values.find { |row| row['sheltered'].nil? }
    expect(small_row).not_to be_nil
  end

  it 'has no census equivalent for the "Other or Unknown" race bucket in the overall row' do
    expect(data['who']['race']['overall'].last).to be_nil
  end

  it 'has one map value entry per population group' do
    expect(data['map']['values'].first.size).to eq(5)
  end

  it 'never leaks a raw count between 1 and 99 in a redacted field (the core privacy guard)' do
    leaks = []

    data['who']['donuts'].each do |id, donut|
      donut['totals'].each { |t| leaks << "donuts.#{id}.totals=#{t}" if t&.between?(1, 99) }
    end

    data['who']['breakdown'].each do |row_id, row|
      row['totals'].each { |t| leaks << "breakdown.#{row_id}.totals=#{t}" if t&.between?(1, 99) }
    end

    data['map']['statewideTotals'].each_with_index do |period_totals, period_index|
      period_totals.each_with_index do |t, group_index|
        leaks << "map.statewideTotals[#{period_index}][#{group_index}]=#{t}" if t&.between?(1, 99)
      end
    end

    expect(leaks).to eq([])
  end
end
