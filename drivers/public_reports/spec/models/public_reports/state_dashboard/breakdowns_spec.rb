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
      filter: { filters: { start: Date.parse('2025-01-01'), end: period_end, project_type_numbers: [1] } },
    )
  end

  # Returns the client id. `client` defaults to a fresh client with no race recorded.
  def create_member(household_id:, age:, head_of_household: false, date: Date.parse('2025-10-15'), client: create(:hud_client, data_source_id: data_source.id), project: self.project, enrollment_group_id: nil)
    she = create(
      :she_entry,
      client: client,
      data_source_id: project.data_source_id,
      project_id: project.project_id,
      organization_id: project.organization_id,
      project_type: 1,
      date: date,
      first_date_in_program: date,
      last_date_in_program: period_end,
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
      project_type: 1,
      age: age,
    )
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

  describe 'household classification' do
    let!(:mixed_hoh) { create_member(household_id: 'mixed', age: 18, head_of_household: true) }
    let!(:child_only_hoh) { create_member(household_id: 'child-only', age: 17, head_of_household: true) }
    let!(:adult_only_hoh) { create_member(household_id: 'adult-only', age: 18, head_of_household: true) }

    before do
      create_member(household_id: 'mixed', age: 10)
    end

    it 'treats an 18-year-old with a child as an adults-with-children household' do
      expect(breakdowns.adult_and_child_household_ids(period_start, period_end)).to eq(household_key('mixed') => mixed_hoh)
    end

    it 'treats a household of only 17-year-olds as child-only' do
      expect(breakdowns.child_only_household_ids(period_start, period_end)).to eq(household_key('child-only') => child_only_hoh)
    end

    it 'treats a household of only 18-year-olds as adult-only' do
      expect(breakdowns.adult_only_household_ids(period_start, period_end)).to eq(household_key('adult-only') => adult_only_hoh)
    end
  end

  # Two flagged heads resolve to the one served last.
  describe 'head of household resolution' do
    let!(:no_hoh_members) { ['no-hoh-1', 'no-hoh-2'].map { |household_id| create_member(household_id: household_id, age: 30) } }
    let!(:earlier_hoh) { create_member(household_id: 'two-hoh', age: 30, head_of_household: true, date: Date.parse('2025-10-10')) }
    let!(:later_hoh) { create_member(household_id: 'two-hoh', age: 40, head_of_household: true, date: Date.parse('2025-10-20')) }

    it 'records nil for a household with no flagged head and the latest-served head when two are flagged' do
      expect(breakdowns.adult_only_household_ids(period_start, period_end)).to eq(household_key('no-hoh-1') => nil, household_key('no-hoh-2') => nil, household_key('two-hoh') => later_hoh)
    end
  end

  describe 'unknown ages' do
    let!(:adult_with_unknown_hoh) { create_member(household_id: 'adult-and-unknown', age: 30, head_of_household: true) }
    let!(:all_unknown_hoh) { create_member(household_id: 'all-unknown', age: nil, head_of_household: true) }

    before do
      create_member(household_id: 'adult-and-unknown', age: nil)
      create_member(household_id: 'all-unknown', age: nil)
    end

    it 'classifies a household as adult-only whether some or all of its members have unknown ages' do
      expect(breakdowns.adult_only_household_ids(period_start, period_end)).to eq(household_key('adult-and-unknown') => adult_with_unknown_hoh, household_key('all-unknown') => all_unknown_hoh)
      expect([breakdowns.adult_and_child_household_ids(period_start, period_end), breakdowns.child_only_household_ids(period_start, period_end)]).to eq([{}, {}])
    end

    it 'records a later known age for a client whose earlier row had an unknown age' do
      client = create(:hud_client, data_source_id: data_source.id)
      hoh = create_member(household_id: 'unknown-then-child', age: nil, head_of_household: true, date: Date.parse('2025-10-10'), client: client)
      create_member(household_id: 'unknown-then-child', age: 10, head_of_household: true, date: Date.parse('2025-10-20'), client: client)

      expect(breakdowns.child_only_household_ids(period_start, period_end)).to eq(household_key('unknown-then-child') => hoh)
    end
  end

  describe 'household identity' do
    before { stub_const('PublicReports::StateDashboard::SUPPRESS_TOTALS_AT_OR_BELOW', 0) }

    it 'keeps households from different data sources apart when they share a HouseholdID' do
      other_source = create(:source_data_source)
      other_organization = create(:hud_organization, data_source_id: other_source.id)
      other_project = create(:hud_project, data_source_id: other_source.id, OrganizationID: other_organization.OrganizationID, ProjectType: 1)
      adult = create_member(household_id: 'shared', age: 30, head_of_household: true)
      child = create_member(household_id: 'shared', age: 10, head_of_household: true, project: other_project, client: create(:hud_client, data_source_id: other_source.id))

      expect(
        [
          breakdowns.adult_only_household_ids(period_start, period_end),
          breakdowns.child_only_household_ids(period_start, period_end),
          breakdowns.adult_and_child_household_ids(period_start, period_end),
        ],
      ).to eq([{ household_key('shared') => adult }, { household_key('shared', other_source) => child }, {}])
    end

    it 'counts an enrollment with no HouseholdID in its household-type row' do
      create_member(household_id: nil, enrollment_group_id: 'enrollment-1', age: 30, head_of_household: true)

      expect(breakdowns.groupings[:household_type][:sections][0][:rows][1]).to eq('Persons over age 24')
      expect(breakdowns.rows['household_type__0__1'][:totals].last).to eq(1)
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
