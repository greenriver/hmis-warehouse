###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'roo'

RSpec.describe 'HomelessSummaryReport::WarehouseReports::Reports#details', type: :request do
  let(:data_source) { create(:data_source_fixed_id) }
  let(:project) { create(:grda_warehouse_hud_project, data_source: data_source) }
  let(:source_client) { create(:hud_client, data_source: data_source, first_name: 'Alix', last_name: 'Realname') }
  let!(:enrollment) { create(:hud_enrollment, client: source_client, project: project) }
  let!(:destination_data_source) { create(:destination_data_source) }
  let(:destination_client) { create(:hud_client, data_source_id: destination_data_source.id) }
  let!(:warehouse_client) { create(:warehouse_client, source_id: source_client.id, destination_id: destination_client.id) }

  let(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: HomelessSummaryReport::Report.url,
      name: 'System Performance Measures by Sub-Population',
      report_group: 'Reports',
      description: 'A summary of SPMs 1, 2, and 7 with sub-population and demographic details',
    )
  end
  let(:access_group) { create(:access_group) }
  let(:role) do
    create(
      :role,
      can_view_all_reports: true,
      can_view_clients: true,
      can_view_client_name: true,
    )
  end
  let(:user) do
    user = create(:user)
    role.add(user)
    access_group.add(user)
    access_group.add_viewable(report_definition)
    user
  end

  let(:report) { HomelessSummaryReport::Report.create!(user_id: user.id) }
  let!(:detail_client) do
    report.clients.create!(
      client_id: destination_client.id,
      first_name: 'Alix',
      last_name: 'Realname',
      spm_all_persons__all: 1,
      spm_m1a_es_sh_days: 5,
      spm_m1a_es_sh_th_days: 0,
      spm_m1b_es_sh_ph_days: 20,
      spm_m1b_es_sh_th_ph_days: 0,
    )
  end

  # Controls whether the signed-in user has view access to the client's underlying
  # (source) project — this is what SourceClientPolicy/DestinationClientPolicy gate PII
  # visibility on, independent of the role's can_view_client_name flag.
  let(:grant_project_access) { true }

  before do
    access_group.add_viewable(project) if grant_project_access
    sign_in(user)
  end

  def rendered_workbook
    excel_file = Tempfile.new(['homeless_summary_report_details', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    Roo::Excelx.new(excel_file.path)
  ensure
    excel_file&.unlink
  end

  describe 'html format' do
    it 'renders the details table with the client visible' do
      get details_homeless_summary_report_warehouse_reports_report_path(report, cell: 'm1b_es_sh_ph_days', variant: 'spm_all_persons__all')

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Alix')
      expect(response.body).to include('Realname')
    end

    it 'renders the empty state when no clients match the cell' do
      get details_homeless_summary_report_warehouse_reports_report_path(report, cell: 'm1a_es_sh_th_days', variant: 'spm_all_persons__all')

      expect(response).to have_http_status(:success)
      expect(response.body).to include('No clients matched the current criteria.')
    end
  end

  describe 'xlsx format' do
    context 'when include_pii_in_detail_downloads is disabled (the default)' do
      before do
        allow(GrdaWarehouse::Config).to receive(:get).and_call_original
        allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(false)
      end

      it 'redacts the client name regardless of the user\'s own PII access' do
        get details_homeless_summary_report_warehouse_reports_report_path(report, cell: 'm1b_es_sh_ph_days', variant: 'spm_all_persons__all', format: :xlsx)

        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Disposition']).to include('attachment')
        expect(response.media_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

        data_row = rendered_workbook.sheet(0).row(3)
        expect(data_row[1]).to eq('Redacted')
        expect(data_row[2]).to eq('Redacted')
      end
    end

    context 'when include_pii_in_detail_downloads is enabled' do
      before do
        allow(GrdaWarehouse::Config).to receive(:get).and_call_original
        allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(true)
      end

      context 'and the user has view access to the client\'s underlying project' do
        let(:grant_project_access) { true }

        it 'exports the real name' do
          get details_homeless_summary_report_warehouse_reports_report_path(report, cell: 'm1b_es_sh_ph_days', variant: 'spm_all_persons__all', format: :xlsx)

          data_row = rendered_workbook.sheet(0).row(3)
          expect(data_row[1]).to eq('Alix')
          expect(data_row[2]).to eq('Realname')
        end
      end

      context 'and the user lacks view access to the client\'s underlying project' do
        let(:grant_project_access) { false }

        it 'still redacts the name' do
          get details_homeless_summary_report_warehouse_reports_report_path(report, cell: 'm1b_es_sh_ph_days', variant: 'spm_all_persons__all', format: :xlsx)

          data_row = rendered_workbook.sheet(0).row(3)
          expect(data_row[1]).to eq('Redacted')
          expect(data_row[2]).to eq('Redacted')
        end
      end
    end

    it 'exports the correct data-cell values and headers' do
      allow(GrdaWarehouse::Config).to receive(:get).and_call_original
      allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(true)

      get details_homeless_summary_report_warehouse_reports_report_path(report, cell: 'm1b_es_sh_ph_days', variant: 'spm_all_persons__all', format: :xlsx)

      sheet = rendered_workbook.sheet(0)
      expect(sheet.row(2)).to eq(['Client', 'First Name', 'Last Name', 'm1a es sh days', 'm1a es sh th days', 'm1b es sh ph days', 'm1b es sh th ph days'])
      data_row = sheet.row(3)
      expect(data_row[0]).to eq(destination_client.id)
      expect(data_row[3]).to eq(5)
      expect(data_row[5]).to eq(20)
    end
  end
end
