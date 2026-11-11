###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'roo'
require_relative '../../../filters/criteria/shared_filter_criteria_context'

RSpec.describe GrdaWarehouse::WarehouseReports::DocumentExports::ActiveClientReportExcelExport do
  include_context 'filter criteria setup'

  let(:filter_params) do
    {
      'start' => '2021-01-01',
      'end' => end_date.iso8601,
      'project_type_codes' => ['es'],
    }
  end

  def create_served_enrollment(project_type:)
    enrollment = create_enrollment_for_client(
      create(:grda_warehouse_hud_client),
      date: start_date + 5.days,
      first_date_in_program: start_date + 5.days,
      last_date_in_program: end_date - 5.days,
      project_type: project_type,
    )
    create(
      :service_history_service,
      service_history_enrollment: enrollment,
      record_type: 200,
      date: enrollment.first_date_in_program + 1.day,
      client_id: enrollment.client_id,
      project_type: project_type,
    )
    enrollment
  end

  def build_export(export_user: user)
    described_class.new(user_id: export_user.id, query_string: { 'filters' => filter_params, 'filter' => filter_params }.to_query)
  end

  describe '#perform' do
    let!(:es_enrollment) { create_served_enrollment(project_type: 1) }

    before { create_served_enrollment(project_type: 3) }

    def workbook_rows(export)
      Tempfile.create(['actives', '.xlsx']) do |file|
        file.binmode
        file.write(export.file_data)
        file.flush
        Roo::Excelx.new(file.path).sheet(0).to_a
      end
    end

    it 'writes one row per enrollment matching the filter, over a multi-year range' do
      export = build_export
      export.perform

      expect(export.status).to eq(described_class::COMPLETED_STATUS)
      expect(export.mime_type).to eq(described_class::EXCEL_MIME_TYPE)
      rows = workbook_rows(export)
      expect(rows.first.first(2)).to eq(['Warehouse Client ID', 'First Name'])
      expect(rows.drop(1).map(&:first)).to eq([es_enrollment.client_id])
    end
  end

  describe '#authorized?' do
    let(:report_definition) do
      GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
        url: ActiveClientReport.url,
        name: 'Active Clients',
        report_group: 'Operational Reports',
        description: 'Active clients',
      )
    end
    let(:report_collection) { create(:collection).tap { |c| c.set_viewables(reports: [report_definition.id]) } }

    def report_user(can_view_clients:)
      create(:acl_user).tap do |report_user|
        report_role = create(:role, can_view_assigned_reports: true, can_view_clients: can_view_clients)
        setup_access_control(report_user, report_role, report_collection)
      end
    end

    it 'allows a user who can see the report and view clients' do
      expect(build_export(export_user: report_user(can_view_clients: true)).authorized?).to be(true)
    end

    it 'refuses a user who can see the report but cannot view clients' do
      expect(build_export(export_user: report_user(can_view_clients: false)).authorized?).to be(false)
    end
  end
end
