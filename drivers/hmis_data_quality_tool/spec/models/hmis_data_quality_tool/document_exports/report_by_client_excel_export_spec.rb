###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'roo'
require_relative '../shared_context'

RSpec.describe HmisDataQualityTool::DocumentExports::ReportByClientExcelExport, type: :model do
  include_context 'DQ Tool test setup'

  let(:include_pii_in_detail_downloads) { true }
  let(:can_view_client_name) { true }
  let!(:report_role) do
    create(
      :role,
      name: 'DQ Tool Test Role - Full Access',
      can_view_project_related_filters: true,
      can_view_assigned_reports: true,
      can_view_projects: true,
      can_view_clients: true,
      can_view_client_name: can_view_client_name,
      can_search_own_clients: true,
    )
  end

  let!(:project) { create_project(project_type: 0) }
  let!(:client) { create_client_with_warehouse_link(first_name: 'Pat', last_name: 'Example') }

  before do
    allow(GrdaWarehouse::Config).to receive(:get).and_call_original
    allow(GrdaWarehouse::Config).to receive(:get).
      with(:include_pii_in_detail_downloads).
      and_return(include_pii_in_detail_downloads)
  end

  def export_rows(report)
    export = described_class.new(user_id: user_with_client_access.id, query_string: { id: report.id }.to_query)
    export.perform
    expect(export.status).to eq(described_class::COMPLETED_STATUS)

    Tempfile.create(['by_client', '.xlsx']) do |file|
      file.binmode
      file.write(export.file_data)
      file.flush
      Roo::Excelx.new(file.path).sheet(0).to_a
    end
  end

  # Header row is the second row; the first holds the merged group titles.
  def header_and_client_row(report)
    rows = export_rows(report)
    header = rows.second
    client_row = rows.drop(2).detect { |row| row[1] == client.personal_id }
    [header, client_row]
  end

  def name_cells(report)
    header, client_row = header_and_client_row(report)
    [
      client_row[header.index('Last Name')],
      client_row[header.index('First Name')],
    ]
  end

  context 'when the user can view client names on the client project' do
    before { create_enrollment(client: client, project: project) }

    it 'writes real names' do
      expect(name_cells(setup_report([project.id]))).to eq(['Example', 'Pat'])
    end
  end

  context 'when the user role on the client project lacks can_view_client_name' do
    let(:can_view_client_name) { false }

    before { create_enrollment(client: client, project: project) }

    it 'redacts names' do
      redacted = GrdaWarehouse::PiiProvider::REDACTED

      expect(name_cells(setup_report([project.id]))).to eq([redacted, redacted])
    end
  end

  context 'when no policy project is found for the client' do
    before { create_enrollment(client: client, project: project) }

    it 'redacts names' do
      report = setup_report([project.id])
      # Deleting the enrollment rows would also break the report's universes, so stub the lookup instead.
      allow_any_instance_of(HmisDataQualityTool::Report).
        to receive(:policy_project_ids_by_destination_client).
        and_return({})
      redacted = GrdaWarehouse::PiiProvider::REDACTED

      expect(name_cells(report)).to eq([redacted, redacted])
    end
  end

  context 'when the user can view names but the client is restricted' do
    before do
      create_enrollment(client: client, project: project)
      DestinationClientRestriction.new(client.destination_client).restrict!(user: user_with_client_access)
    end

    it 'redacts names' do
      redacted = GrdaWarehouse::PiiProvider::REDACTED

      expect(name_cells(setup_report([project.id]))).to eq([redacted, redacted])
    end
  end

  context 'when the client is in two projects and the user can view names in only one' do
    # unnamed_project must get the lower id so it is the client's first project; the export must
    # still pick the named one. The outer let!(:project) hook runs before this group's hooks, so
    # project creates unnamed_project itself to fix the order.
    let(:unnamed_project) { create_project(project_type: 0) }
    let(:project) do
      unnamed_project
      create_project(project_type: 0)
    end
    let(:data_sources_collection) do
      create(:collection).tap { |collection| collection.set_viewables({ projects: [project.id] }) }
    end
    let(:report_only_role) do
      create(
        :role,
        name: 'DQ Tool Test Role - Reports Only',
        can_view_project_related_filters: true,
        can_view_assigned_reports: true,
        can_view_projects: true,
      )
    end

    before do
      unnamed_collection = create(:collection).tap { |collection| collection.set_viewables({ projects: [unnamed_project.id] }) }
      setup_access_control(user_with_client_access, report_only_role, unnamed_collection)
      create_enrollment(client: client, project: unnamed_project, entry_date: '2022-11-01'.to_date, exit_date: '2022-12-15'.to_date, household_id: 'unnamed_household')
      create_enrollment(client: client, project: project)
    end

    it 'writes real names' do
      expect(unnamed_project.id).to be < project.id

      report = setup_report([unnamed_project.id, project.id])

      expect(report.enrollments.distinct.pluck(:project_id)).to contain_exactly(unnamed_project.id, project.id)
      expect(name_cells(report)).to eq(['Example', 'Pat'])
    end
  end

  context 'when include_pii_in_detail_downloads is off' do
    let(:include_pii_in_detail_downloads) { false }

    before { create_enrollment(client: client, project: project) }

    it 'leaves out the name columns' do
      header, client_row = header_and_client_row(setup_report([project.id]))

      expect(header).not_to include('Last Name', 'First Name')
      expect(client_row).not_to include('Example', 'Pat')
    end
  end
end
