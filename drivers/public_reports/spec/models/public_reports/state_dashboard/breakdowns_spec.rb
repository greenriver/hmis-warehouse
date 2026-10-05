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

  # Returns the client id.
  def create_member(household_id:, age:, head_of_household: false)
    client = create(:hud_client, data_source_id: data_source.id)
    she = create(
      :she_entry,
      client: client,
      data_source_id: data_source.id,
      project_id: project.project_id,
      organization_id: project.organization_id,
      project_type: 1,
      date: Date.parse('2025-10-15'),
      first_date_in_program: Date.parse('2025-10-15'),
      last_date_in_program: period_end,
      household_id: household_id,
      head_of_household: head_of_household,
    )
    create(
      :service_history_service,
      service_history_enrollment_id: she.id,
      client_id: client.id,
      record_type: 'service',
      date: Date.parse('2025-10-15'),
      project_type: 1,
      age: age,
    )
    client.id
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
      expect(breakdowns.adult_and_child_household_ids(period_start, period_end)).to eq('mixed' => mixed_hoh)
    end

    it 'treats a household of only 17-year-olds as child-only' do
      expect(breakdowns.child_only_household_ids(period_start, period_end)).to eq('child-only' => child_only_hoh)
    end

    it 'treats a household of only 18-year-olds as adult-only' do
      expect(breakdowns.adult_only_household_ids(period_start, period_end)).to eq('adult-only' => adult_only_hoh)
    end
  end
end
