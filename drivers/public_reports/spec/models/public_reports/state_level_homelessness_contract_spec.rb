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
# a raw small integer. Map counts are random unless fake_map_counts? is stubbed to false.
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
  let(:outreach_project) { create(:hud_project, data_source_id: source_data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 4) }

  let(:report_start) { Date.parse('2025-01-01') }
  let(:report_end) { Date.parse('2025-12-31') }

  # Gender lives directly on the client SHE.client_id points at. Race is only
  # resolvable through a WarehouseClient link to a separate "source" client
  # (see Hud::Client's race_white/race_am_ind_ak_native/etc scopes, which
  # join WarehouseClient.source) -- so each of these builds both.
  def create_homeless_client_and_entry(gender:, race_field:, household_id:, project: self.project, age: 30)
    dest_client = create(:hud_client, data_source_id: destination_data_source.id, gender => 1, DOB: Date.parse('2025-10-15') - age.years)
    race_source_client = create(:hud_client, data_source_id: source_data_source.id, race_field => 1)
    create(:warehouse_client, destination_id: dest_client.id, source_id: race_source_client.id, data_source_id: source_data_source.id)

    she = create(
      :she_entry,
      client: dest_client,
      data_source_id: source_data_source.id,
      project_id: project.project_id,
      organization_id: project.organization_id,
      project_type: project.project_type,
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
        project_type: project.project_type,
        age: age,
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

  around do |example|
    travel_to(Date.parse('2026-06-15')) { example.run }
  end

  it 'has schema_version 2' do
    expect(data['schema_version']).to eq(2)
  end

  it 'records the data-through date and the map type the map was computed for' do
    expect([data['data_through'], data['map']['map_type']]).to eq(['2025-12-31', PublicReports::Setting.first_or_create.map_type])
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
      expect(row['sheltered'].size).to eq(periods_size) unless row['sheltered'].nil?
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

  it 'never leaks a raw count between 1 and 100 in a redacted field (the core privacy guard)' do
    leaks = []

    data['who']['donuts'].each do |id, donut|
      donut['totals'].each { |t| leaks << "donuts.#{id}.totals=#{t}" if t&.between?(1, 100) }
    end

    data['who']['breakdown'].each do |row_id, row|
      row['totals'].each { |t| leaks << "breakdown.#{row_id}.totals=#{t}" if t&.between?(1, 100) }
    end

    data['who']['race']['totals'].each { |t| leaks << "race.totals=#{t}" if t&.between?(1, 100) }

    data['map']['statewideTotals'].each_with_index do |period_totals, period_index|
      period_totals.each_with_index do |t, group_index|
        leaks << "map.statewideTotals[#{period_index}][#{group_index}]=#{t}" if t&.between?(1, 100)
      end
    end

    expect(leaks).to eq([])
  end

  context 'when the adults-with-children section is over the total threshold but each of its rows is not' do
    before do
      stub_const('PublicReports::StateLevelHomelessness::SUPPRESS_TOTALS_AT_OR_BELOW', 5)
      stub_const('PublicReports::StateLevelHomelessness::MIN_THRESHOLD', 2)
      # 4 households, each one adult and one child: 2 sheltered, 2 unsheltered.
      # Children row = 4 and adults-over-24 row = 4 (both at or below 5); section = 8.
      4.times do |i|
        project_for_household = i.even? ? project : outreach_project
        [5, 30].each do |age|
          create_homeless_client_and_entry(gender: :Woman, race_field: :White, household_id: "family-#{i}", project: project_for_household, age: age)
        end
      end
    end

    it 'suppresses each row by its own total, not the section total' do
      children = data['who']['breakdown']['household_type__1__0']

      expect([children['totals'].last, children['sheltered']&.last, children['unsheltered'].last]).to eq([nil, nil, nil])
    end

    it 'still publishes a row whose own total is over the threshold' do
      gender_rows = data['who']['breakdownGroupings']['gender']['sections'][0]['rows']
      woman_row = data['who']['breakdown']["gender__0__#{gender_rows.index { |label| label.match?(/wom/i) }}"]

      # 3 women from the shared setup plus 8 here.
      expect(woman_row['totals'].last).to eq(11)
    end
  end

  context 'with real map counts' do
    before do
      allow_any_instance_of(described_class).to receive(:fake_map_counts?).and_return(false) # rubocop:disable RSpec/AnyInstance
    end

    it 'suppresses a small statewide total and counts no one aged 30 as youth' do
      all_homeless, youth = data['map']['statewideTotals'].last.first(2)

      expect([all_homeless, youth]).to eq([nil, 0])
    end
  end

  context 'when a row has at least MIN_THRESHOLD sheltered and unsheltered clients but a total of 100 or less' do
    before do
      12.times do |i|
        create_homeless_client_and_entry(gender: :Woman, race_field: :White, household_id: "sheltered-#{i}")
        create_homeless_client_and_entry(gender: :Woman, race_field: :White, household_id: "unsheltered-#{i}", project: outreach_project)
      end
    end

    it 'suppresses the sheltered and unsheltered counts along with the total' do
      leaks = data['who']['breakdown'].flat_map do |row_id, row|
        row['totals'].each_index.filter_map do |i|
          next unless row['totals'][i].nil?

          located = [row['sheltered']&.at(i), row['unsheltered'][i]].compact
          "#{row_id}[#{i}]=#{located}" if located.any?
        end
      end

      expect(leaks).to eq([])
    end
  end

  context 'with census race populations for the state CoC' do
    before do
      coc = GrdaWarehouse::Shape::Coc.create!(st: 'MA', cocnum: 'MA-500', full_geoid: 'CUSTOMCOCUSMA-500')
      populations = {
        'POP::TOTAL' => 1000,
        'POP::WHITE_ALONE' => 907,
        'POP::BLACK_OR_AFRICAN_AMERICAN_ALONE' => 50,
        'POP::AMERICAN_INDIAN_AND_ALASKA_NATIVE_ALONE' => 2,
        'POP::ASIAN_ALONE' => 18,
        'POP::NATIVE_HAWAIIAN_AND_OTHER_PACIFIC_ISLANDER_ALONE' => 1,
        'POP::SOME_OTHER_RACE_ALONE' => 7,
        'POP::TWO_OR_MORE_RACES' => 15,
      }
      populations.each_with_index do |(internal_name, value), i|
        variable = GrdaWarehouse::UsCensusApi::CensusVariable.create!(
          year: 2024, dataset: 'acs5', name: "B0200#{i}_001E", label: internal_name, concept: 'Race',
          census_group: 'B02001', census_attributes: "B0200#{i}_001EA", internal_name: internal_name, created_on: Date.current
        )
        GrdaWarehouse::UsCensusApi::CensusValue.create!(
          census_variable: variable, value: value, full_geoid: coc.full_geoid, census_level: 'CUSTOM', created_on: Date.current,
        )
      end
    end

    it 'stores the overall population share of each race as a number' do
      race = data['who']['race']

      expect(race['overall'][race['labels'].index('White')]).to eq(90.7)
    end
  end
end
