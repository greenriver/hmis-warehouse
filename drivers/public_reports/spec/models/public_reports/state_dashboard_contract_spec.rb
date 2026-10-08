###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Contract spec for PublicReports::StateDashboard#chart_data (schema_version 2).
# This is the guard against a client-privacy redaction regression: everything below
# MIN_THRESHOLD (11) or the 100-person donut/breakdown floor must come back nil, never
# a raw small integer. Map counts are real in test; MapData#fake_counts? is development-only.
RSpec.describe PublicReports::StateDashboard, type: :model do
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
  def create_homeless_client(gender:, race_field:, age:)
    dest_client = create(:hud_client, data_source_id: destination_data_source.id, gender => 1, DOB: Date.parse('2025-10-15') - age.years)
    race_source_client = create(:hud_client, data_source_id: source_data_source.id, race_field => 1)
    create(:warehouse_client, destination_id: dest_client.id, source_id: race_source_client.id, data_source_id: source_data_source.id)
    dest_client
  end

  def add_homeless_entry(client:, household_id:, project:, age:)
    she = create(
      :she_entry,
      client: client,
      data_source_id: project.data_source_id,
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
        client_id: client.id,
        record_type: 'service',
        date: date,
        project_type: project.project_type,
        age: age,
      )
    end
  end

  def create_homeless_client_and_entry(gender:, race_field:, household_id:, project: self.project, age: 30)
    client = create_homeless_client(gender: gender, race_field: race_field, age: age)
    add_homeless_entry(client: client, household_id: household_id, project: project, age: age)
    client
  end

  def gender_row(label)
    labels = data['who']['breakdownGroupings']['gender']['sections'][0]['rows']
    data['who']['breakdown']["gender__0__#{labels.index(label)}"]
  end

  def add_exited_entry(client:, destination:)
    create(
      :she_entry,
      client: client,
      data_source_id: project.data_source_id,
      project_id: project.project_id,
      organization_id: project.organization_id,
      project_type: project.project_type,
      date: Date.parse('2025-03-01'),
      first_date_in_program: Date.parse('2025-03-01'),
      last_date_in_program: Date.parse('2025-06-30'),
      destination: destination,
      household_id: "exited-#{client.id}",
    )
  end

  # A 'first' row has no exit, so the inflow query's open_between keeps it in
  # range and only started_between can exclude it.
  def add_first_homeless_date(client:, date:, project: self.project)
    create(
      :she_first,
      client: client,
      data_source_id: project.data_source_id,
      project_id: project.project_id,
      organization_id: project.organization_id,
      project_type: project.project_type,
      date: date,
      first_date_in_program: date,
      last_date_in_program: nil,
    )
  end

  # Breakdowns joins SHE -> Hud::Enrollment -> ChEnrollment on
  # [data_source_id, enrollment_group_id, project_id], so the entry needs a
  # real enrollment row to reach its chronic flag.
  def set_chronic_status(client:, chronic:)
    she = GrdaWarehouse::ServiceHistoryEnrollment.entry.find_by!(client_id: client.id)
    enrollment = create(:hud_enrollment, data_source_id: she.data_source_id, ProjectID: she.project_id)
    she.update!(enrollment_group_id: enrollment.EnrollmentID)
    GrdaWarehouse::ChEnrollment.create!(enrollment: enrollment, chronically_homeless_at_entry: chronic)
  end

  # Dotted key paths; arrays of hashes recurse as "key[]", arrays of scalars
  # are leaves, because the test DB has no shapes and so no per-town values.
  def key_paths(node, prefix = nil)
    case node
    when Hash then node.flat_map { |key, value| key_paths(value, [prefix, key].compact.join('.')) }
    when Array then node.grep(Hash).flat_map { |value| key_paths(value, "#{prefix}[]") }.presence || [prefix]
    else [prefix]
    end
  end

  let(:collection) { Collection.system_collection(:data_sources) }

  # A handful of clients, spread across race/gender, all entered in the
  # report's final quarter -- small enough that every donut/breakdown total
  # should come back suppressed, which is exactly the case this spec exists
  # to guard.
  before do
    setup_access_control(user, role, collection)

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

  let(:project_type_numbers) { [1, 2, 8, 4] }
  let(:coc_codes) { nil }

  let(:report) do
    report = described_class.new(
      user: user,
      filter: { filters: { start: report_start, end: report_end, project_type_numbers: project_type_numbers, coc_codes: coc_codes }.compact },
    )
    report.save!
    report.run_and_save!
    report
  end

  let(:data) { report.parsed_pre_calculated_data }

  around do |example|
    travel_to(Date.parse('2026-06-15')) { example.run }
  end

  it 'records the data-through date and the map type the map was computed for' do
    PublicReports::Setting.first_or_create.update!(map_type: 'place')

    expect([data['data_through'], data['map']['map_type']]).to eq(['2025-12-31', 'place'])
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

  it 'publishes no chronic percent for a row whose total is suppressed' do
    leaks = data['who']['breakdown'].flat_map do |row_id, row|
      row['totals'].each_index.filter_map do |i|
        "#{row_id}[#{i}]=#{row['chronic'][i]}" if row['totals'][i].nil? && !row['chronic'][i].nil?
      end
    end

    expect(leaks).to eq([])
  end

  it 'publishes the summary tiles with small counts shown as "100 or fewer" and the unsheltered share not reported' do
    GrdaWarehouse::ServiceHistoryEnrollment.update_all(head_of_household: true)

    expect(data['summary']['tiles'].map { |tile| tile['value'] }).to eq(['100 or fewer', '100 or fewer', 'Not reported'])
  end

  it 'publishes one PIT value per PIT year, raising a small count to the 100 floor' do
    expect(data['pit_chart']).to eq('labels' => ['2025'], 'series' => [{ 'label' => 'People served in ES, SO, SH, or TH', 'values' => [100] }])
  end

  context 'with a client who exited to a permanent destination during the year' do
    before do
      add_exited_entry(client: create_homeless_client(gender: :Man, race_field: :White, age: 30), destination: HudHelper.util.permanent_destinations.first)
    end

    it 'counts the exit at the 100 floor and no first-time entries' do
      expect(data['inflow_outflow']['series'].map { |series| series['values'] }).to eq([[0], [100]])
    end

    context 'plus a temporary-destination exit and first-time entries inside and before the year, with totals unsuppressed' do
      before do
        stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
        temporary_exit_client = create_homeless_client(gender: :Man, race_field: :White, age: 30)
        add_exited_entry(client: temporary_exit_client, destination: HudHelper.util.temporary_destinations.first)
        add_first_homeless_date(client: temporary_exit_client, date: Date.parse('2025-03-01'))
        earlier_client = create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'first-before-window')
        add_first_homeless_date(client: earlier_client, date: Date.parse('2023-05-01'))
      end

      it 'counts one first-time entry and one permanent-destination exit' do
        expect(data['inflow_outflow']['series'].map { |series| series['values'] }).to eq([[1], [1]])
      end
    end
  end

  context 'when the report ends partway through its last PIT year' do
    let(:report_start) { Date.parse('2024-02-01') }
    let(:report_end) { Date.parse('2025-11-30') }

    it 'stars the partial year and notes the data-through date' do
      expect(data['pit_chart'].values_at('labels', 'note')).to eq([['2025*'], '2025 reflects data through Nov 30, 2025'])
    end

    it 'emits every key the request-spec fixture renders from' do
      fixture = JSON.parse(File.read(Rails.root.join('spec/fixtures/files/public_reports/state_level_v2.json')))

      expect(key_paths(fixture) - key_paths(data)).to eq([])
    end

    it 'leaves service after the report end date out of the last period' do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      client = create_homeless_client(gender: :Man, race_field: :White, age: 30)
      she = create(
        :she_entry,
        client: client,
        data_source_id: project.data_source_id,
        project_id: project.project_id,
        organization_id: project.organization_id,
        project_type: project.project_type,
        date: Date.parse('2025-11-20'),
        first_date_in_program: Date.parse('2025-11-20'),
        last_date_in_program: Date.parse('2025-12-31'),
        household_id: 'december-service-only',
      )
      create(
        :service_history_service,
        service_history_enrollment_id: she.id,
        client_id: client.id,
        record_type: 'service',
        date: Date.parse('2025-12-15'),
        project_type: project.project_type,
        age: 30,
      )

      # The last period is Oct 1 - Nov 30; this client's only service is Dec 15.
      expect(data['who']['donuts']['all-people']['totals'].last).to eq(5)
    end
  end

  describe 'date span validation' do
    def report_for(start, finish)
      described_class.new(user: user, filter: { filters: { start: Date.parse(start), end: Date.parse(finish), project_type_numbers: [1] } })
    end

    # filter_object moves the end date to the end of its month, so the boundary is a whole month.
    it 'accepts a span of exactly twelve months and rejects eleven' do
      expect([report_for('2025-01-01', '2025-12-31').valid?, report_for('2025-01-01', '2025-11-30').valid?]).to eq([true, false])
    end
  end

  context 'when one client is served in both a shelter and an outreach project, with totals unsuppressed' do
    before do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      client = create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'both-1')
      add_homeless_entry(client: client, household_id: 'both-2', project: outreach_project, age: 30)
    end

    it 'counts that client once in the all-people donut total' do
      expect(data['who']['donuts']['all-people']['totals'].last).to eq(6)
    end

    it 'counts that client once in the statewide map total' do
      expect(data['map']['statewideTotals'].last.first).to eq(6)
    end

    it 'counts that client once in the PIT count' do
      expect(data['pit_chart']['series'].first['values']).to eq([6])
    end
  end

  context 'when the report covers shelters only and a client also has an outreach stay, with totals unsuppressed' do
    let(:project_type_numbers) { [1] }

    before do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      client = create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'shelter-stay')
      add_homeless_entry(client: client, household_id: 'outreach-stay', project: outreach_project, age: 30)
      create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'outreach-only', project: outreach_project)
    end

    it 'counts the shelter stay but not the outreach stays' do
      # 5 fixture clients + the shelter client = 6; counting the outreach stay makes the tile 1 of 6 (17%).
      expect([data['who']['donuts']['all-people']['totals'].last, data['summary']['tiles'].last['value']]).to eq([6, '0%'])
    end

    it 'counts a first-time date outside the filter for a client with a shelter stay, and none for an outreach-only client' do
      shelter_client = GrdaWarehouse::ServiceHistoryEnrollment.entry.find_by!(household_id: 'shelter-stay').client
      outreach_only_client = GrdaWarehouse::ServiceHistoryEnrollment.entry.find_by!(household_id: 'outreach-only').client
      add_first_homeless_date(client: shelter_client, date: Date.parse('2025-03-01'), project: outreach_project)
      add_first_homeless_date(client: outreach_only_client, date: Date.parse('2025-03-01'), project: outreach_project)

      expect(data['inflow_outflow']['series'].map { |series| series['values'] }).to eq([[1], [0]])
    end
  end

  context 'when the report is limited to one CoC, with totals unsuppressed' do
    let(:coc_codes) { ['MA-500'] }
    let(:other_coc_project) { create(:hud_project, data_source_id: source_data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 1) }

    before do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      create(:hud_project_coc, data_source: source_data_source, ProjectID: project.ProjectID, CoCCode: 'MA-500')
      create(:hud_project_coc, data_source: source_data_source, ProjectID: other_coc_project.ProjectID, CoCCode: 'MA-501')
      create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'other-coc', project: other_coc_project)
    end

    it 'counts the clients in that CoC and not the client in another CoC' do
      expect(data['who']['donuts']['all-people']['totals'].last).to eq(5)
    end
  end

  context 'with one sheltered and one unsheltered veteran, and totals unsuppressed' do
    before do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      sheltered = create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'veteran-sheltered')
      unsheltered = create_homeless_client_and_entry(gender: :Woman, race_field: :White, household_id: 'veteran-unsheltered', project: outreach_project)
      [sheltered, unsheltered].each { |client| client.update!(VeteranStatus: 1) }
    end

    it 'counts only the veterans in the veterans donut' do
      veterans = data['who']['donuts']['veterans']

      expect([veterans['totals'].last, veterans['values'].last]).to eq([2, [50, 50]])
    end
  end

  context 'with a two-person household and a head of household with two stays, and totals unsuppressed' do
    before do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      member = create_homeless_client_and_entry(gender: :Woman, race_field: :White, household_id: 'household-0')
      twice_enrolled = GrdaWarehouse::ServiceHistoryEnrollment.entry.find_by!(household_id: 'household-1').client
      add_homeless_entry(client: twice_enrolled, household_id: 'second-stay', project: outreach_project, age: 30)
      GrdaWarehouse::ServiceHistoryEnrollment.update_all(head_of_household: true)
      GrdaWarehouse::ServiceHistoryEnrollment.where(client_id: member.id).update_all(head_of_household: false)
    end

    it 'counts each head of household and each person once' do
      # 5 heads (one with two stays); 6 people; 1 of 6 unsheltered = 17%.
      expect(data['summary']['tiles'].map { |tile| tile['value'] }).to eq(['5', '6', '17%'])
    end
  end

  context 'with enrollments the filter must exclude, and totals unsuppressed' do
    let(:ph_project) { create(:hud_project, data_source_id: source_data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 3) }
    let(:other_data_source) { create(:grda_warehouse_data_source) }
    let(:other_organization) { create(:hud_organization, data_source_id: other_data_source.id) }
    let(:other_project) { create(:hud_project, data_source_id: other_data_source.id, OrganizationID: other_organization.OrganizationID, ProjectType: 1) }
    let(:other_outreach_project) { create(:hud_project, data_source_id: other_data_source.id, OrganizationID: other_organization.OrganizationID, ProjectType: 4) }
    # Every data source is auto-added to the system collection in test, so grant only the source data source.
    let(:collection) { create(:collection).tap { |c| c.set_viewables({ data_sources: [source_data_source.id] }) } }

    before do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'permanent-housing', project: ph_project)
      create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'other-data-source', project: other_project)
    end

    it 'counts neither the permanent housing enrollment nor the one the owner cannot see' do
      expect(data['who']['donuts']['all-people']['totals'].last).to eq(5)
    end

    it 'does not count an outreach stay the owner cannot see for a client whose shelter stay is visible' do
      client = create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'visible-shelter')
      add_homeless_entry(client: client, household_id: 'hidden-outreach', project: other_outreach_project, age: 30)

      expect([data['who']['donuts']['all-people']['totals'].last, data['summary']['tiles'].last['value']]).to eq([6, '0%'])
    end

    context 'when the owner can also see the other data source' do
      let(:collection) { create(:collection).tap { |c| c.set_viewables({ data_sources: [source_data_source.id, other_data_source.id] }) } }

      it 'counts the client from the other data source and still excludes permanent housing' do
        expect(data['who']['donuts']['all-people']['totals'].last).to eq(6)
      end

      it 'counts that outreach stay once the owner can see its data source' do
        client = create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'visible-shelter')
        add_homeless_entry(client: client, household_id: 'visible-outreach', project: other_outreach_project, age: 30)

        # 5 fixture clients + the other-data-source client + this client = 7; 1 of 7 unsheltered = 14%.
        expect([data['who']['donuts']['all-people']['totals'].last, data['summary']['tiles'].last['value']]).to eq([7, '14%'])
      end
    end
  end

  context 'with a 24-year-old in an adult-only household and totals unsuppressed' do
    before do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'age-24', age: 24)
    end

    it 'counts the 24-year-old in the 18 to 24 row only' do
      rows = data['who']['breakdown']

      expect([rows['household_type__0__0']['totals'].last, rows['household_type__0__1']['totals'].last]).to eq([1, 5])
    end
  end

  context 'with a chronically homeless parent and totals unsuppressed' do
    before do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      parent = create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'chronic-family', age: 30)
      child = create_homeless_client_and_entry(gender: :Woman, race_field: :White, household_id: 'chronic-family', age: 5)
      set_chronic_status(client: parent, chronic: true)
      set_chronic_status(client: child, chronic: false)
    end

    it 'rounds a small row to the nearest ten percent and sums the adults-with-children section across its rows' do
      man_row = gender_row('Man')
      children_row = data['who']['breakdown']['household_type__1__0']
      parents_row = data['who']['breakdown']['household_type__1__2']

      # Man row: 2 shared + parent = 3, 1 chronic -> 33 -> 30.
      # Adults-with-children rows share one count: 1 chronic of 2 people -> 50.
      expect([man_row['chronic'].last, children_row['chronic'].last, parents_row['chronic'].last]).to eq([30, 50, 50])
    end
  end

  it 'has no census equivalent for the "Other or Unknown" race bucket in the overall row' do
    expect(data['who']['race']['overall'].last).to be_nil
  end

  it 'publishes every under-100 race bucket as 0% and the whole group under "Other or Unknown"' do
    race = data['who']['race']

    expect(race['labels'].zip(race['homeless'].last).to_h).to eq(
      race['labels'].to_h { |label| [label, label == 'Other or Unknown' ? 100.0 : 0.0] },
    )
  end

  it 'never leaks a raw count between 1 and 100 in a redacted field (the core privacy guard)' do
    expect(data['who']['donuts']['all-people']['totals']).to include(nil)
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

  it 'zeroes donut percentages for a group under 100 people with a part under 11' do
    expect(data['who']['donuts'].transform_values { |donut| donut['values'].last }).to eq(
      'all-people' => [0, 0],
      'veterans' => [0, 0],
      'household-type' => [0, 0, 0],
    )
  end

  context 'when the adults-with-children section is over the total threshold but each of its rows is not' do
    before do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 5)
      stub_const('PublicReports::StateDashboard::MIN_THRESHOLD', 2)
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
      woman_row = gender_row('Woman')

      # 3 women from the shared setup plus 8 here.
      expect(woman_row['totals'].last).to eq(11)
    end

    context 'with three more men, putting the Man row exactly at the threshold' do
      before do
        3.times { |i| create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: "man-at-#{i}") }
      end

      it 'suppresses a row whose total equals SUPPRESS_TOTALS_AT_OR_BELOW' do
        row = gender_row('Man')

        # 2 shared + 3 = 5, exactly the stubbed constant.
        expect([row['totals'].last, row['sheltered']&.last, row['unsheltered'].last]).to eq([nil, nil, nil])
      end
    end

    context 'with four more men, two of them unsheltered' do
      before do
        2.times { |i| create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: "man-sheltered-#{i}") }
        2.times { |i| create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: "man-unsheltered-#{i}", project: outreach_project) }
      end

      it 'publishes a row one over the threshold with an unsheltered count exactly at MIN_THRESHOLD' do
        row = gender_row('Man')

        # total 6, sheltered 2 shared + 2, unsheltered 2 == MIN_THRESHOLD.
        expect([row['totals'].last, row['sheltered'].last, row['unsheltered'].last]).to eq([6, 4, 2])
      end
    end

    context 'with four more men, one of them unsheltered' do
      before do
        3.times { |i| create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: "man-sheltered-#{i}") }
        create_homeless_client_and_entry(gender: :Man, race_field: :White, household_id: 'man-unsheltered', project: outreach_project)
      end

      it 'publishes the total but masks both location counts when unsheltered is one under MIN_THRESHOLD' do
        row = gender_row('Man')

        expect([row['totals'].last, row['sheltered']&.last, row['unsheltered'].last]).to eq([6, nil, nil])
      end
    end
  end

  it 'suppresses a small statewide total and counts no one aged 30 as youth' do
    all_homeless, youth = data['map']['statewideTotals'].last.first(2)

    expect([all_homeless, youth]).to eq([nil, 0])
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

    it 'publishes location percentages rounded to ten when both parts reach MIN_THRESHOLD' do
      # 5 shared + 12 sheltered = 17, 12 unsheltered, of 29: 59% -> 60, 41% -> 40.
      expect(data['who']['donuts']['all-people']['values'].last).to eq([60, 40])
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
