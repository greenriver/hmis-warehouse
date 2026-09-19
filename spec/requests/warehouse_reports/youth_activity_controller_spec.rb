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

  # Helper to create an intake with a specific updated_at datetime
  def create_intake(client, updated_at:, engagement_date: Date.current)
    GrdaWarehouse::YouthIntake::Entry.create!(
      client: client,
      engagement_date: engagement_date,
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
  end

  # Helper to create a DirectFinancialAssistance with a specific updated_at datetime
  def create_dfa(client, updated_at:, provided_on: Date.current)
    GrdaWarehouse::Youth::DirectFinancialAssistance.create!(
      client: client,
      user: user,
      type_provided: 'Rent',
      provided_on: provided_on,
      updated_at: updated_at,
    )
  end

  # Helper to create a CaseManagement with a specific updated_at datetime
  def create_case_management(client, updated_at:, engaged_on: Date.current)
    GrdaWarehouse::Youth::YouthCaseManagement.create!(
      client: client,
      user: user,
      activity: 'Prevention',
      housing_status: 'foo',
      engaged_on: engaged_on,
      updated_at: updated_at,
    )
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

  context 'when activity was updated on the same day (datetime comparison)' do
    it 'includes intakes updated in the evening (after midnight UTC)' do
      evening_timestamp = Time.current.change(hour: 20, minute: 0, second: 0)

      create_intake(restricted_destination_client, updated_at: evening_timestamp)
      create_intake(open_destination_client, updated_at: evening_timestamp)

      get warehouse_reports_youth_activity_index_path(filter: filter_params)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Name Redacted')
      expect(response.body).to include('Open Client')
    end

    it 'includes DFA updated in the evening (after midnight UTC)' do
      evening_timestamp = Time.current.change(hour: 22, minute: 30, second: 0)

      create_dfa(restricted_destination_client, updated_at: evening_timestamp)
      create_dfa(open_destination_client, updated_at: evening_timestamp)

      get warehouse_reports_youth_activity_index_path(filter: filter_params)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Name Redacted')
      expect(response.body).to include('Open Client')
    end

    it 'includes case management updated in the evening (after midnight UTC)' do
      evening_timestamp = Time.current.change(hour: 23, minute: 59, second: 59)

      create_case_management(restricted_destination_client, updated_at: evening_timestamp)
      create_case_management(open_destination_client, updated_at: evening_timestamp)

      get warehouse_reports_youth_activity_index_path(filter: filter_params)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Name Redacted')
      expect(response.body).to include('Open Client')
    end

    it 'includes records updated at exactly midnight' do
      midnight_timestamp = Time.current.change(hour: 0, minute: 0, second: 0)

      create_intake(restricted_destination_client, updated_at: midnight_timestamp)
      create_intake(open_destination_client, updated_at: midnight_timestamp)

      get warehouse_reports_youth_activity_index_path(filter: filter_params)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Name Redacted')
      expect(response.body).to include('Open Client')
    end
  end

  context 'when records are outside the date range' do
    it 'excludes intakes updated before the start date' do
      old_timestamp = 2.days.ago.change(hour: 23, minute: 59, second: 59)

      create_intake(restricted_destination_client, updated_at: old_timestamp)
      create_intake(open_destination_client, updated_at: old_timestamp)

      get warehouse_reports_youth_activity_index_path(filter: filter_params)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('No modifications were made')
      expect(response.body).not_to include('Name Redacted')
      expect(response.body).not_to include('Open Client')
    end

    it 'excludes intakes updated after the end date' do
      future_timestamp = 2.days.from_now.change(hour: 0, minute: 0, second: 0)

      create_intake(restricted_destination_client, updated_at: future_timestamp)
      create_intake(open_destination_client, updated_at: future_timestamp)

      get warehouse_reports_youth_activity_index_path(filter: filter_params)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('No modifications were made')
      expect(response.body).not_to include('Name Redacted')
      expect(response.body).not_to include('Open Client')
    end
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
