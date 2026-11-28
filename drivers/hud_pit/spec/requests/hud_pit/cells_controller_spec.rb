###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HudPit::CellsController#show', type: :request do
  let!(:user) { create(:acl_user) }
  let!(:report) do
    create(
      :hud_reports_report_instance,
      user: user,
      report_name: 'Point in Time Count - FY 2025',
      options: { 'report_version' => 'fy2025' },
    )
  end
  let!(:cell) { report.report_cells.create!(question: 'Additional Homeless Populations', cell_name: 'B2') }
  let(:hiv_permitted) { true }
  let(:cell_params) { { pit_id: report.id, question_id: 'Additional Homeless Populations', id: 'B2', table: 'Additional Homeless Populations' } }

  before do
    grant_hud_report(user, 'hud_reports/pits', role: create(:role, can_view_assigned_reports: true, can_view_hiv_status: hiv_permitted))
    sign_in user
  end

  def build_preload_client(index, in_cell: cell)
    source = create(:grda_warehouse_hud_client, FirstName: "Preload#{index}", LastName: 'Coverage')
    destination = create(:grda_warehouse_hud_client, FirstName: "Preload#{index}", LastName: 'Coverage')
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: source.data_source_id, id_in_source: source.id.to_s)
    pit_client = HudPit::Fy2022::PitClient.create!(
      report_instance_id: report.id,
      client_id: source.id,
      destination_client_id: destination.id,
      data_source_id: source.data_source_id,
      first_name: source.FirstName,
      last_name: source.LastName,
    )
    HudReports::UniverseMember.create!(report_cell: in_cell, universe_membership: pit_client, client_id: destination.id)
    destination
  end

  it 'lists every client in the cell when more clients than the preload miss threshold are in it' do
    extra = Array.new(preload_miss_client_count) { |i| build_preload_client(i) }

    get hud_reports_pit_question_cell_path(cell_params)

    expect(response).to have_http_status(:ok)
    extra.each { |client| expect(response.body).to include(client.FirstName) }
  end

  context 'with a client in the HIV/AIDS row of Additional Homeless Populations' do
    let(:hiv_row_label) { "B#{HudPit::Generators::Pit::Fy2025::AdditionalHomelessPopulations::HIV_AIDS_ROW}" }
    let!(:hiv_cell) { report.report_cells.create!(question: 'Additional Homeless Populations', cell_name: hiv_row_label) }
    let!(:hiv_client) { build_preload_client('HivRow', in_cell: hiv_cell) }
    let(:hiv_params) { cell_params.merge(id: hiv_row_label) }
    let(:redirect_path) { result_hud_reports_pit_question_path(pit_id: report.id, id: 'Additional Homeless Populations') }
    let(:denial_alert) { 'You do not have permission to view HIV/AIDS drilldown data.' }

    def workbook_cell_values
      file = Tempfile.new(['pit_cell', '.xlsx'])
      file.binmode
      file.write(response.body)
      file.close
      sheet = Roo::Excelx.new(file.path)
      sheet.each_row_streaming.flat_map { |row| row.map(&:value) }.compact.map(&:to_s)
    ensure
      file&.unlink
    end

    context 'when the user can view HIV status' do
      it 'lists the client on the canonical URL' do
        get hud_reports_pit_question_cell_path(hiv_params)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(hiv_client.FirstName)
      end
    end

    context 'when the user cannot view HIV status' do
      let(:hiv_permitted) { false }

      it 'redirects the canonical URL with the HIV denial alert' do
        get hud_reports_pit_question_cell_path(hiv_params)

        expect(response).to redirect_to(redirect_path)
        expect(flash[:alert]).to eq(denial_alert)
      end

      it 'lists clients only from the requested question\'s table in html' do
        get hud_reports_pit_question_cell_path(hiv_params.merge(question_id: 'Projects'))

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(hiv_client.FirstName)
      end

      it 'lists clients only from the requested question\'s table in xlsx' do
        get hud_reports_pit_question_cell_path(hiv_params.merge(question_id: 'Projects', format: :xlsx))

        expect(workbook_cell_values.select { |v| v.include?(hiv_client.FirstName) }).to be_empty
      end

      it 'denies the HIV/AIDS row through authorize_with when the HIV redirect does not run' do
        allow(HudPit::CellsController).to receive(:new).and_wrap_original do |original, *args|
          original.call(*args).tap { |controller| allow(controller).to receive(:enforce_hiv_drilldown_access) }
        end

        get hud_reports_pit_question_cell_path(hiv_params)

        expect(response).to redirect_to(warehouse_reports_path)
        expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
      end

      it 'checks the HIV/AIDS row of the run\'s recorded version when the filter names another version' do
        fy2023_hiv_row = HudPit::Generators::Pit::Fy2023::AdditionalHomelessPopulations::HIV_AIDS_ROW
        expect(fy2023_hiv_row).not_to eq(HudPit::Generators::Pit::Fy2025::AdditionalHomelessPopulations::HIV_AIDS_ROW)

        get hud_reports_pit_question_cell_path(hiv_params.merge(filter: { report_version: 'fy2023' }))

        expect(response).to redirect_to(redirect_path)
        expect(flash[:alert]).to eq(denial_alert)
      end

      it 'takes the question from the route, not from a question parameter' do
        get hud_reports_pit_question_cell_path(hiv_params.merge(question: 'Projects'))

        expect(response).to redirect_to(redirect_path)
        expect(flash[:alert]).to eq(denial_alert)
      end
    end
  end
end
