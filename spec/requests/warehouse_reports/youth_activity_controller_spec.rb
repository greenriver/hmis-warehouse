###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../shared_contexts/hud_enrollment_builders'

RSpec.describe 'WarehouseReports::YouthActivityController#index', type: :request do
  include_context 'HUD enrollment builders'

  let!(:user) { create(:acl_user) }
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_clients: true, can_view_projects: true, can_view_client_name: true, can_view_youth_intake: true) }
  let!(:report) { create(:touch_point_report, url: 'warehouse_reports/youth_activity', name: 'Youth Activity') }

  let!(:hmis_user) { create(:hmis_user, data_source: destination_data_source) }
  let!(:project) { create_project(project_type: 1) }
  let!(:restricted_source_client) { create_client_with_warehouse_link(first_name: 'Restricted', last_name: 'Client') }
  let!(:open_source_client) { create_client_with_warehouse_link(first_name: 'Open', last_name: 'Client') }
  let(:restricted_destination_client) { restricted_source_client.destination_client }
  let(:open_destination_client) { open_source_client.destination_client }

  # Rails only honors an explicit updated_at when nothing touches the row afterward; the reload check
  # keeps the timestamp-boundary examples from silently degrading to "created now".
  def with_updated_at(record, updated_at)
    expect(record.reload.updated_at).to be_within(1.second).of(updated_at)
    record
  end

  def create_intake(client, updated_at:)
    intake = GrdaWarehouse::YouthIntake::Entry.create!(
      client: client,
      engagement_date: Date.current,
      exit_date: nil,
      turned_away: false,
      staff_name: 'Staff',
      staff_email: 'staff@example.com',
      unaccompanied: false,
      street_outreach_contact: false,
      housing_status: 'foo',
      other_agency_involvements: 'none',
      secondary_education: 'foo',
      attending_college: false,
      health_insurance: false,
      staff_believes_youth_under_24: false,
      client_gender: 'foo',
      client_lgbtq: false,
      client_primary_language: 'English',
      pregnant_or_parenting: false,
      needs_shelter: false,
      in_stable_housing: false,
      youth_experiencing_homelessness_at_start: false,
      client_race: 'foo',
      disabilities: 'none',
      requesting_financial_assistance: false,
      updated_at: updated_at,
    )
    with_updated_at(intake, updated_at)
  end

  def create_dfa(client, updated_at:)
    dfa = GrdaWarehouse::Youth::DirectFinancialAssistance.create!(
      client: client,
      user: user,
      type_provided: 'Rent',
      provided_on: Date.current,
      updated_at: updated_at,
    )
    with_updated_at(dfa, updated_at)
  end

  def create_case_management(client, updated_at:)
    case_management = GrdaWarehouse::Youth::YouthCaseManagement.create!(
      client: client,
      user: user,
      activity: 'Prevention',
      housing_status: 'foo',
      engaged_on: Date.current,
      updated_at: updated_at,
    )
    with_updated_at(case_management, updated_at)
  end

  def create_follow_up(client, updated_at:)
    follow_up = GrdaWarehouse::Youth::YouthFollowUp.create!(
      client: client,
      user: user,
      contacted_on: Date.current,
      required_on: Date.current,
      updated_at: updated_at,
    )
    with_updated_at(follow_up, updated_at)
  end

  def create_referral(client, updated_at:)
    referral = GrdaWarehouse::Youth::YouthReferral.create!(
      client: client,
      user: user,
      referred_on: Date.current,
      referred_to: 'Shelter',
      updated_at: updated_at,
    )
    with_updated_at(referral, updated_at)
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    create_enrollment(client: restricted_source_client, project: project, entry_date: Date.current)
    create_enrollment(client: open_source_client, project: project, entry_date: Date.current)
    Hmis::Hud::Client.find(restricted_source_client.id).mark_as_restricted!(user: hmis_user)

    sign_in user
  end

  # Every timestamp below is relative to "today"; freezing keeps a run that crosses midnight Eastern from flaking.
  around { |example| travel_to(Time.zone.local(2026, 9, 19, 12)) { example.run } }

  let(:filter_params) { { start: Date.current.to_s, end: Date.current.to_s } }

  # One example per query in the controller; each compares updated_at (a datetime) against the Date filter.
  {
    'intakes' => :create_intake,
    'direct financial assistance' => :create_dfa,
    'case management' => :create_case_management,
    'follow-ups' => :create_follow_up,
    'referrals' => :create_referral,
  }.each do |label, builder|
    it "includes #{label} updated at the end of the end date" do
      send(builder, open_destination_client, updated_at: Time.current.change(hour: 23, minute: 59, second: 59))

      get warehouse_reports_youth_activity_index_path(filter: filter_params)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Open Client')
    end
  end

  it 'includes intakes updated at the start of the start date' do
    create_intake(open_destination_client, updated_at: Time.current.change(hour: 0, minute: 0, second: 0))

    get warehouse_reports_youth_activity_index_path(filter: filter_params)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Open Client')
  end

  it 'excludes intakes updated at the end of the day before the start date' do
    create_intake(open_destination_client, updated_at: 1.day.ago.change(hour: 23, minute: 59, second: 59))

    get warehouse_reports_youth_activity_index_path(filter: filter_params)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('No modifications were made')
    expect(response.body).not_to include('Open Client')
  end

  it 'excludes intakes updated at the start of the day after the end date' do
    create_intake(open_destination_client, updated_at: 1.day.from_now.change(hour: 0, minute: 0, second: 0))

    get warehouse_reports_youth_activity_index_path(filter: filter_params)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('No modifications were made')
    expect(response.body).not_to include('Open Client')
  end

  it 'redacts the restricted client name' do
    timestamp = Time.current.change(hour: 12, minute: 0, second: 0)

    create_intake(restricted_destination_client, updated_at: timestamp)
    create_intake(open_destination_client, updated_at: timestamp)

    get warehouse_reports_youth_activity_index_path(filter: filter_params)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('Restricted')
    expect(response.body).to include('Name Redacted')
    expect(response.body).to include('Open Client')
  end
end
