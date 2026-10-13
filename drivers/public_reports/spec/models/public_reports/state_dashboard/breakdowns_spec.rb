###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateDashboard::Breakdowns, type: :model do
  subject(:breakdowns) { described_class.new(report) }

  let(:user) { create(:acl_user) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:data_source) { create(:data_source_fixed_id) }
  let(:organization) { create(:hud_organization, data_source_id: data_source.id) }
  let(:project) { create(:hud_project, data_source_id: data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 1) }
  let(:period_start) { Date.parse('2025-10-01') }
  let(:period_end) { Date.parse('2025-12-31') }
  let(:report) do
    PublicReports::StateDashboard.new(
      user: user,
      filter: { filters: { start: Date.parse('2025-01-01'), end: period_end, project_type_numbers: [1, 4] } },
    )
  end

  # Returns the client id. `client` defaults to a fresh client with no race recorded.
  # A chronic member gets a Hud::Enrollment and ChEnrollment, which Breakdowns reaches through enrollment_group_id.
  def create_member(household_id:, age:, head_of_household: false, date: Date.parse('2025-10-15'), last_date: period_end, client: create(:hud_client, data_source_id: data_source.id), project: self.project, enrollment_group_id: nil, chronic: false)
    she = create(
      :she_entry,
      client: client,
      data_source_id: project.data_source_id,
      project_id: project.project_id,
      organization_id: project.organization_id,
      project_type: project.project_type,
      date: date,
      first_date_in_program: date,
      last_date_in_program: last_date,
      household_id: household_id,
      enrollment_group_id: enrollment_group_id,
      head_of_household: head_of_household,
    )
    create(
      :service_history_service,
      service_history_enrollment_id: she.id,
      client_id: client.id,
      record_type: 'service',
      date: date,
      project_type: project.project_type,
      age: age,
    )
    if chronic
      enrollment = create(:hud_enrollment, data_source_id: she.data_source_id, ProjectID: she.project_id)
      she.update!(enrollment_group_id: enrollment.EnrollmentID)
      GrdaWarehouse::ChEnrollment.create!(enrollment: enrollment, chronically_homeless_at_entry: true)
    end
    client.id
  end

  def household_key(household_id, source = data_source)
    "#{source.id}:#{household_id}"
  end

  before do
    travel_to(Date.parse('2026-06-15'))
    setup_access_control(user, role, Collection.system_collection(:data_sources))
  end

  after { travel_back }

  def household_types
    breakdowns.household_type_counts(period_start, period_end)
  end

  describe 'household classification' do
    before do
      create_member(household_id: 'mixed', age: 18, head_of_household: true)
      create_member(household_id: 'mixed', age: 10)
      create_member(household_id: 'child-only', age: 17, head_of_household: true)
      create_member(household_id: 'adult-only', age: 18, head_of_household: true)
      create_member(household_id: 'adult-only-2', age: 40, head_of_household: true)
    end

    it 'classifies an 18-year-old with a child as adults-with-children, only 17-year-olds as child-only and only adults as adult-only' do
      expect(household_types).to eq('adult_only' => 2, 'adult_and_child' => 1, 'child_only' => 1)
    end
  end

  # The no-head households count once each; two-hoh and later-own share the later head, so they count once together.
  describe 'head of household resolution' do
    let(:later_client) { create(:hud_client, data_source_id: data_source.id) }

    before do
      ['no-hoh-1', 'no-hoh-2'].each { |household_id| create_member(household_id: household_id, age: 30) }
      create_member(household_id: 'two-hoh', age: 30, head_of_household: true, date: Date.parse('2025-10-10'))
      create_member(household_id: 'two-hoh', age: 40, head_of_household: true, date: Date.parse('2025-10-20'), client: later_client)
      create_member(household_id: 'later-own', age: 40, head_of_household: true, client: later_client)
    end

    it 'counts a household with no flagged head on its own and a household with two flagged heads under the head served last' do
      expect(household_types['adult_only']).to eq(3)
    end
  end

  describe 'unknown ages' do
    it 'classifies a household as adult-only whether some or all of its members have unknown ages' do
      create_member(household_id: 'adult-and-unknown', age: 30, head_of_household: true)
      create_member(household_id: 'adult-and-unknown', age: nil)
      create_member(household_id: 'all-unknown', age: nil, head_of_household: true)
      create_member(household_id: 'all-unknown', age: nil)

      expect(household_types).to eq('adult_only' => 2, 'adult_and_child' => 0, 'child_only' => 0)
    end

    it 'uses a later known age for a client whose earlier service had an unknown age' do
      client = create(:hud_client, data_source_id: data_source.id)
      create_member(household_id: 'unknown-then-child', age: nil, head_of_household: true, date: Date.parse('2025-10-10'), client: client)
      create_member(household_id: 'unknown-then-child', age: 10, head_of_household: true, date: Date.parse('2025-10-20'), client: client)

      expect(household_types).to eq('adult_only' => 0, 'adult_and_child' => 0, 'child_only' => 1)
    end

    it 'classifies by the age at the earliest service when a client turns 18 during the period' do
      client = create(:hud_client, data_source_id: data_source.id)
      create_member(household_id: 'turns-18', age: 17, head_of_household: true, date: Date.parse('2025-10-10'), client: client)
      create_member(household_id: 'turns-18', age: 18, head_of_household: true, date: Date.parse('2025-10-20'), client: client)
      create_member(household_id: 'turns-18', age: -1, date: Date.parse('2025-10-05'), client: client)

      expect(household_types).to eq('adult_only' => 0, 'adult_and_child' => 0, 'child_only' => 1)
    end
  end

  describe 'household identity' do
    before { stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0) }

    it 'keeps households from different data sources apart when they share a HouseholdID' do
      other_source = create(:source_data_source)
      other_organization = create(:hud_organization, data_source_id: other_source.id)
      other_project = create(:hud_project, data_source_id: other_source.id, OrganizationID: other_organization.OrganizationID, ProjectType: 1)
      create_member(household_id: 'shared', age: 30, head_of_household: true)
      create_member(household_id: 'shared', age: 10, head_of_household: true, project: other_project, client: create(:hud_client, data_source_id: other_source.id))

      expect(household_types).to eq('adult_only' => 1, 'adult_and_child' => 0, 'child_only' => 1)
    end

    it 'treats each enrollment with no HouseholdID as its own household' do
      create_member(household_id: nil, enrollment_group_id: 'enrollment-adult', age: 30, head_of_household: true)
      create_member(household_id: nil, enrollment_group_id: 'enrollment-child', age: 10, head_of_household: true)

      expect(household_types).to eq('adult_only' => 1, 'adult_and_child' => 0, 'child_only' => 1)
    end

    # Two households with no flagged head, plus one head flagged in two households.
    it 'counts each household without a head once and a head of several households once in the household-type donut' do
      create_member(household_id: 'no-hoh-1', age: 30)
      create_member(household_id: 'no-hoh-2', age: 30)
      client = create(:hud_client, data_source_id: data_source.id)
      create_member(household_id: 'first-stay', age: 40, head_of_household: true, client: client)
      create_member(household_id: 'second-stay', age: 40, head_of_household: true, client: client)

      donut = PublicReports::StateDashboard::WhoData.new(report).to_h[:donuts]['household-type']
      expect(donut[:totals].last).to eq(3)
    end

    it 'leaves a soft-deleted member out of household classification and the row counts' do
      stub_const('PublicReports::StateDashboard::MIN_THRESHOLD', 0)
      deleted = create(:hud_client, data_source_id: data_source.id)
      create_member(household_id: 'deleted-parent', age: 35, head_of_household: true, client: deleted)
      create_member(household_id: 'deleted-parent', age: 5)
      deleted.destroy!

      expect([household_types, breakdowns.rows['household_type__2__0'][:totals].last, breakdowns.rows['household_type__1__2'][:totals].last]).to eq(
        [{ 'adult_only' => 0, 'adult_and_child' => 0, 'child_only' => 1 }, 1, 0],
      )
    end

    it 'reports every household type as zero for a period with no enrollments' do
      expect(breakdowns.household_type_counts(Date.parse('2025-04-01'), Date.parse('2025-06-30'))).to eq('adult_only' => 0, 'adult_and_child' => 0, 'child_only' => 0)
    end
  end

  describe '#published_row_totals' do
    before { stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 100) }

    it 'also hides the smallest published non-zero row when exactly one row is hidden' do
      expect(breakdowns.published_row_totals([500, 40, 300, 0])).to eq([500, nil, nil, 0])
    end

    it 'hides no extra row when two rows are already hidden' do
      expect(breakdowns.published_row_totals([500, 40, 30, 300])).to eq([500, nil, nil, 300])
    end

    it 'treats 100 as hidden and 101 as published' do
      expect(breakdowns.published_row_totals([101, 100, 400])).to eq([nil, nil, 400])
    end

    it 'hides nothing more when every other row is zero' do
      expect(breakdowns.published_row_totals([40, 0, 0])).to eq([nil, 0, 0])
    end

    it 'publishes every row when none is hidden' do
      expect(breakdowns.published_row_totals([500, 300, 0])).to eq([500, 300, 0])
    end
  end

  describe 'query volume' do
    it 'reads service history enrollments once per period' do
      create_member(household_id: 'one', age: 30, head_of_household: true)
      create_member(household_id: 'two', age: 10, head_of_household: true)
      statements = []
      ActiveSupport::Notifications.subscribed(->(*, payload) { statements << payload[:sql] }, 'sql.active_record') { breakdowns.rows }

      expect(statements.grep(/FROM "service_history_enrollments"/).size).to eq(report.iteration_dates.size)
    end
  end

  describe 'row counts' do
    let(:so_project) { create(:hud_project, data_source_id: data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 4) }
    let(:rows) { breakdowns.rows }

    def new_client(**attributes)
      create(:hud_client, data_source_id: data_source.id, **attributes)
    end

    # Fourth-quarter value of each series in a row.
    def q4(row_id)
      rows[row_id].transform_values { |series| series[3] }
    end

    before do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      stub_const('PublicReports::StateDashboard::MIN_THRESHOLD', 0)

      # Sheltered at 20 and unsheltered at 30 in the same quarter.
      split = new_client
      create_member(household_id: 'split-es', age: 20, head_of_household: true, client: split)
      create_member(household_id: 'split-so', age: 30, head_of_household: true, client: split, project: so_project)

      create_member(household_id: 'woman', age: 40, head_of_household: true, client: new_client(Woman: 1), project: so_project, chronic: true)

      create_member(household_id: 'family-1', age: 35, head_of_household: true, client: new_client(Man: 1), chronic: true)
      create_member(household_id: 'family-1', age: 5)

      # Chronic only through an adult-only household.
      parent = new_client
      create_member(household_id: 'single', age: 50, head_of_household: true, client: parent, chronic: true)
      create_member(household_id: 'family-2', age: 50, head_of_household: true, client: parent)
      create_member(household_id: 'family-2', age: 6)

      create_member(household_id: 'q1-only', age: 30, head_of_household: true, date: Date.parse('2025-02-01'), last_date: Date.parse('2025-02-28'))
    end

    it 'places a client in the sheltered or unsheltered column of an age row by the enrollment in that age band' do
      expect([q4('household_type__0__0'), q4('household_type__0__1')]).to eq(
        [
          { totals: 1, chronic: 0, sheltered: 1, unsheltered: 0 },
          { totals: 3, chronic: 70, sheltered: 1, unsheltered: 2 },
        ],
      )
    end

    # Combined chronic 1 (family-1 head) over combined total 4 is 25%, published as 30.
    it 'pools the adults-with-children chronic percent across rows, counting chronic enrollments in that section only' do
      expect([q4('household_type__1__0'), q4('household_type__1__2')]).to eq(
        [
          { totals: 2, chronic: 30, sheltered: 2, unsheltered: 0 },
          { totals: 2, chronic: 30, sheltered: 2, unsheltered: 0 },
        ],
      )
    end

    it 'counts gender rows from the client record' do
      expect([q4('gender__0__0'), q4('gender__0__1')]).to eq(
        [
          { totals: 1, chronic: 100, sheltered: 0, unsheltered: 1 },
          { totals: 1, chronic: 100, sheltered: 1, unsheltered: 0 },
        ],
      )
    end

    it 'counts each period from services in that period only' do
      expect(rows['household_type__0__1'][:totals]).to eq([1, 0, 0, 3])
    end

    context 'when one gender row is hidden' do
      before do
        stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 2)
        create_member(household_id: 'trans', age: 30, head_of_household: true, client: new_client(Transgender: 1))
        2.times { |i| create_member(household_id: "man-#{i}", age: 30, head_of_household: true, client: new_client(Man: 1)) }
        3.times { |i| create_member(household_id: "woman-#{i}", age: 30, head_of_household: true, client: new_client(Woman: 1)) }
      end

      # Q4 genders: Woman 4 (3 here plus the outer 'woman'), Man 3 (2 here plus 'family-1'), Transgender 1.
      it 'hides the smallest published row with it, including its chronic and location columns' do
        expect((0..2).map { |i| q4("gender__0__#{i}") }).to eq(
          [
            { totals: 4, chronic: 30, sheltered: 3, unsheltered: 1 },
            { totals: nil, chronic: nil, sheltered: nil, unsheltered: nil },
            { totals: nil, chronic: nil, sheltered: nil, unsheltered: nil },
          ],
        )
      end
    end
  end

  describe 'race rows' do
    let(:destination_data_source) { create(:grda_warehouse_data_source) }

    def create_linked_client(destination_race:, source_race:)
      destination = create(:hud_client, data_source_id: destination_data_source.id, **destination_race)
      source = create(:hud_client, data_source_id: data_source.id, **source_race)
      create(:warehouse_client, destination: destination, source: source, data_source_id: data_source.id)
      destination
    end

    before do
      stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0)
      create_member(household_id: 'both', age: 30, head_of_household: true, client: create_linked_client(destination_race: { White: 1 }, source_race: { White: 1 }))
      create_member(household_id: 'source-only', age: 30, head_of_household: true, client: create_linked_client(destination_race: {}, source_race: { White: 1 }))
    end

    # The race chart resolves through the source client instead.
    it 'counts a client in the White row only when the destination client record carries the race' do
      expect(breakdowns.groupings[:race][:sections][0][:rows][4]).to eq('White')
      expect(breakdowns.rows['race__0__4'][:totals].last).to eq(1)
    end
  end
end
