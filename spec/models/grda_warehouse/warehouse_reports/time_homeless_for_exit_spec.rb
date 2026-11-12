###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::TimeHomelessForExit, type: :model do
  describe '#rows_for_export' do
    let!(:running_user) { create(:acl_user) }
    let!(:role) do
      create(
        :role,
        can_view_project_related_filters: true,
        can_view_assigned_reports: true,
        can_view_projects: true,
        can_view_client_name: true,
        can_view_clients: true,
      )
    end
    let!(:collection) { create(:collection) }

    let!(:hmis_ds) { create(:hmis_primary_data_source) }
    let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
    let!(:organization) { create(:hud_organization, data_source: hmis_ds) }
    let!(:project) { create(:hud_project, data_source: hmis_ds, OrganizationID: organization.OrganizationID, ProjectType: 1) } # ES

    let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
    let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
    let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Open', last_name: 'Client') }
    let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Client') }

    let(:destination_code) { HudHelper.util.permanent_destinations.first }
    let(:entry_date) { 6.months.ago.to_date }
    let(:exit_date) { 1.month.ago.to_date }

    # `clients_with_permanent_exits` walks a real `GrdaWarehouse::Hud::Enrollment` joined to its
    # `Hud::Exit`; `homeless_entries` separately walks the destination client's
    # `ServiceHistoryEnrollment`, which must point back at that same `Enrollment` for
    # `client_homeless_entry_dates` to resolve a project name for the row.
    def build_exit_with_entry(source_client:, destination_client:)
      enrollment = create(:hud_enrollment, PersonalID: source_client.PersonalID, ProjectID: project.ProjectID, data_source: hmis_ds, EntryDate: entry_date)
      create(:hud_exit, EnrollmentID: enrollment.EnrollmentID, PersonalID: enrollment.PersonalID, data_source: hmis_ds, ExitDate: exit_date, Destination: destination_code)
      she = create(:she_entry, client: destination_client, project: project, enrollment: enrollment, record_type: :entry, project_type: 1, first_date_in_program: entry_date, last_date_in_program: nil)
      create(:service_history_service, service_history_enrollment: she, client: destination_client, date: entry_date, record_type: 'service')
      she
    end
    let!(:restricted_enrollment) { build_exit_with_entry(source_client: restricted_source_client, destination_client: restricted_destination_client) }
    let!(:open_enrollment) { build_exit_with_entry(source_client: open_source_client, destination_client: open_destination_client) }

    let(:filter) { ::Filters::FilterBase.new(user_id: running_user.id, start: 1.year.ago.to_date, end: Date.current) }
    let(:report) { described_class.new(filter) }

    before do
      Collection.maintain_system_groups
      collection.set_viewables({ projects: [project.id] })
      setup_access_control(running_user, role, collection)
      GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
      GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
      restricted_source_client.mark_as_restricted!(user: hmis_user)
    end

    after { GrdaWarehouse::Config.invalidate_cache }

    it 'redacts the restricted client and shows the real name for the unrestricted client when the download toggle is on' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)

      rows = report.rows_for_export
      restricted_row = row_by_header(report.headers_for_export, rows, key: restricted_destination_client.id)
      open_row = row_by_header(report.headers_for_export, rows, key: open_destination_client.id)

      expect(restricted_row.values_at('First Name', 'Last Name')).to eq(['Name Redacted', 'Name Redacted'])
      expect(open_row.values_at('First Name', 'Last Name')).to eq(['Open', 'Client'])
    end

    it 'omits the name columns entirely when the download toggle is off' do
      GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: false)
      GrdaWarehouse::Config.invalidate_cache

      rows = report.rows_for_export
      restricted_row = row_by_header(report.headers_for_export, rows, key: restricted_destination_client.id)

      expect(restricted_row.keys).not_to include('First Name', 'Last Name')
    end
  end

  describe '#data' do
    let!(:running_user) { create(:acl_user) }
    let!(:role) { create(:role, can_view_assigned_reports: true, can_view_projects: true, can_view_clients: true) }
    let!(:collection) { create(:collection) }

    let!(:data_source) { create(:source_data_source) }
    let!(:organization) { create(:hud_organization, data_source: data_source) }
    let!(:visible_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: 1) } # ES
    let!(:hidden_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectType: 1) } # ES

    let!(:source_client) { create(:hud_client, data_source: data_source) }
    let!(:destination_client) { create(:grda_warehouse_hud_client) }

    let(:hidden_entry_date) { 9.months.ago.to_date }
    let(:visible_entry_date) { 6.months.ago.to_date }
    let(:exit_date) { 1.month.ago.to_date }

    def homeless_stay(project:, entry_date:)
      enrollment = create(:hud_enrollment, PersonalID: source_client.PersonalID, ProjectID: project.ProjectID, data_source: data_source, EntryDate: entry_date)
      she = create(:she_entry, client: destination_client, project: project, enrollment: enrollment, record_type: :entry, project_type: 1, first_date_in_program: entry_date, last_date_in_program: nil)
      create(:service_history_service, service_history_enrollment: she, client: destination_client, date: entry_date, record_type: 'service')
      enrollment
    end

    before do
      Collection.maintain_system_groups
      collection.set_viewables({ projects: [visible_project.id] })
      setup_access_control(running_user, role, collection)
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: source_client.id, data_source_id: data_source.id, id_in_source: source_client.PersonalID)

      visible_enrollment = homeless_stay(project: visible_project, entry_date: visible_entry_date)
      create(:hud_exit, EnrollmentID: visible_enrollment.EnrollmentID, PersonalID: source_client.PersonalID, data_source: data_source, ExitDate: exit_date, Destination: HudHelper.util.permanent_destinations.first)
    end

    let(:row) do
      filter = ::Filters::FilterBase.new(user_id: running_user.id, start: 1.year.ago.to_date, end: Date.current)
      described_class.new(filter).data.find { |r| r.client.id == destination_client.id }
    end

    it 'shows the name and ID of a project the user can report on' do
      expect(row.entry_date).to eq(visible_entry_date)
      expect(row.project_name).to eq(visible_project.ProjectName)
      expect(row.project_id).to eq(visible_project.id)
    end

    context 'with an earlier ongoing stay in a project the user can\'t report on' do
      before do
        homeless_stay(project: hidden_project, entry_date: hidden_entry_date)
      end

      it 'counts the hidden stay toward days homeless but masks the project' do
        expect(row.entry_date).to eq(hidden_entry_date)
        expect(row.days).to eq((exit_date - hidden_entry_date).to_i)
        expect(row.project_name).to eq(GrdaWarehouse::Hud::Project.confidential_project_name)
        expect(row.project_id).to be_nil
      end
    end
  end

  # `client_scope` merges the user's visible projects and then the selected projects; both
  # restrictions must apply, so the selection narrows the visible set rather than replacing it
  describe '#client_scope' do
    let!(:running_user) { create(:acl_user) }
    let!(:role) { create(:role, can_view_assigned_reports: true, can_view_projects: true, can_view_clients: true) }
    let!(:collection) { create(:collection) }

    let!(:data_source) { create(:source_data_source) }
    let!(:organization) { create(:hud_organization, data_source: data_source) }
    let!(:selected_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
    let!(:unselected_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
    let!(:hidden_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }

    def destination_client_enrolled_in(project)
      source_client = create(:hud_client, data_source: data_source)
      destination_client = create(:grda_warehouse_hud_client)
      GrdaWarehouse::WarehouseClient.create!(
        destination_id: destination_client.id,
        source_id: source_client.id,
        data_source_id: data_source.id,
        id_in_source: source_client.PersonalID,
      )
      create(:hud_enrollment, PersonalID: source_client.PersonalID, ProjectID: project.ProjectID, data_source: data_source)
      destination_client
    end
    let!(:selected_client) { destination_client_enrolled_in(selected_project) }
    let!(:unselected_client) { destination_client_enrolled_in(unselected_project) }
    let!(:hidden_client) { destination_client_enrolled_in(hidden_project) }

    def client_ids_for(project_ids:)
      filter = ::Filters::FilterBase.new(user_id: running_user.id, project_ids: project_ids)
      described_class.new(filter).send(:client_scope).distinct.pluck(:id)
    end

    before do
      Collection.maintain_system_groups
      collection.set_viewables({ projects: [selected_project.id, unselected_project.id] })
      setup_access_control(running_user, role, collection)
    end

    it 'returns clients of the selected visible project but not of an unselected visible project' do
      client_ids = client_ids_for(project_ids: [selected_project.id])

      expect(client_ids).to include(selected_client.id)
      expect(client_ids).not_to include(unselected_client.id, hidden_client.id)
    end

    it 'returns clients of every visible project when no project is selected' do
      client_ids = client_ids_for(project_ids: [])

      expect(client_ids).to include(selected_client.id, unselected_client.id)
      expect(client_ids).not_to include(hidden_client.id)
    end

    it 'returns no clients when only a hidden project is selected' do
      expect(client_ids_for(project_ids: [hidden_project.id])).to be_empty
    end
  end
end
