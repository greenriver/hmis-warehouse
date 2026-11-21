###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../models/generators/fy2026/hopwa_caper_shared_context'

RSpec.describe HopwaCaper::CellsController, type: :request do
  include_context 'HOPWA CAPER shared context'

  let(:tbra_funder) { hud_code(:funding_sources, 'HUD: HOPWA - Permanent Housing (facility based or TBRA)') }
  let(:project) { create_hopwa_project(funder: tbra_funder) }
  let(:report) { create_report([project]) }
  let(:hiv_role) { create(:role, can_view_hiv_status: true, can_view_client_name: true) }
  let(:denial) { 'You do not have permission to view HIV/AIDS drilldown data.' }
  let(:cell) do
    report.report_cells.detect { |c| c.universe_members.exists? }
  end
  let(:question) do
    generator.questions.keys.find { |q| report.existing_universe(q)&.metadata&.fetch('tables', [])&.include?(cell.question) }
  end
  let(:cell_path_args) { { hopwa_caper_id: report.id, question_id: question, id: cell.cell_name, table: cell.question } }
  let(:extra_rows) { nil }
  let(:xlsx_with_json_accept) { 'application/json, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' }
  let(:result_path) { result_hud_reports_hopwa_caper_question_path(hopwa_caper_id: report.id, id: question) }

  before do
    create_hiv_positive_enrollment(
      client: create_client_with_warehouse_link(first_name: 'Ann', last_name: 'Able'),
      project: project,
      entry_date: report_start_date,
      household_id: Hmis::Hud::Base.generate_uuid,
      relationship_to_ho_h: 1,
    )
    extra_rows
    run_report(report)
    grant_hud_report(user, 'hud_reports/hopwa_capers')
    sign_in(user)
  end

  context 'when the user can view HIV status on the project' do
    before { grant_project_access(user, hiv_role, [project], mode: :acl) }

    it 'renders the cell drilldown' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Ann')
    end

    it 'sends the xlsx drilldown as an attachment' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args.merge(format: :xlsx))

      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Disposition']).to start_with('attachment; filename=')
    end

    it 'links populated cells on the result page' do
      get result_path

      expect(response.body).to include(hud_reports_hopwa_caper_question_cell_path(cell_path_args))
    end
  end

  context 'when detail downloads exclude PII' do
    before do
      grant_project_access(user, hiv_role, [project], mode: :acl)
      allow(GrdaWarehouse::Config).to receive(:get).and_call_original
      allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(false)
    end

    it 'still renders the HTML drilldown' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args)

      expect(response).to have_http_status(:ok)
    end

    it 'redirects the xlsx drilldown with the denial alert' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args.merge(format: :xlsx))

      expect(response).to redirect_to(result_path)
      expect(response.headers['Content-Disposition']).to be_nil
      expect(flash[:alert]).to eq(denial)
    end

    it 'redirects without a file when the request accepts an xlsx media type alongside another type' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args), headers: { 'Accept' => xlsx_with_json_accept }

      expect(response).to redirect_to(result_path)
      expect(response.headers['Content-Disposition']).to be_nil
      expect(flash[:alert]).to eq(denial)
    end
  end

  context 'when the question is not complete' do
    before do
      grant_project_access(user, hiv_role, [project], mode: :acl)
      report.universe(question).update!(status: 'Started')
    end

    it 'redirects to the result page without rendering rows' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args)

      expect(response).to redirect_to(result_path)
      expect(flash[:alert]).to eq('This drilldown is not available.')
    end

    it 'redirects the xlsx drilldown without sending a file' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args.merge(format: :xlsx))

      expect(response).to redirect_to(result_path)
      expect(response.headers['Content-Disposition']).to be_nil
    end
  end

  context 'when the table belongs to a different question than the requested one' do
    let(:other_question) do
      generator.questions.keys.find do |q|
        q != question && report.existing_universe(q)&.status == 'Completed' &&
          !Array(report.existing_universe(q).metadata['tables']).include?(cell.question)
      end
    end
    let(:other_result_path) { result_hud_reports_hopwa_caper_question_path(hopwa_caper_id: report.id, id: other_question) }

    before { grant_project_access(user, hiv_role, [project], mode: :acl) }

    it 'redirects the HTML drilldown to the requested question result' do
      expect(other_question).to be_present

      get hud_reports_hopwa_caper_question_cell_path(cell_path_args.merge(question_id: other_question))

      expect(response).to redirect_to(other_result_path)
      expect(flash[:alert]).to eq('This drilldown is not available.')
    end

    it 'redirects the xlsx drilldown without sending a file' do
      expect(other_question).to be_present

      get hud_reports_hopwa_caper_question_cell_path(cell_path_args.merge(question_id: other_question, format: :xlsx))

      expect(response).to redirect_to(other_result_path)
      expect(response.headers['Content-Disposition']).to be_nil
    end
  end

  context 'when the request has no table param' do
    before { grant_project_access(user, hiv_role, [project], mode: :acl) }

    it 'redirects to the question result without rendering rows' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args.except(:table))

      expect(response).to redirect_to(result_path)
      expect(flash[:alert]).to eq('This drilldown is not available.')
    end
  end

  context 'when the cell holds only service rows on a project without HIV access' do
    let(:strmu_funder) { HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance') }
    let(:service_project) { create_hopwa_project(funder: strmu_funder) }
    let(:report) { create_report([project, service_project]) }
    let(:extra_rows) do
      create_enrolled_client_with_service(client_attrs: {}, project: service_project, entry_date: report_start_date)
    end
    let(:cell) do
      report.report_cells.detect do |c|
        types = c.universe_members.pluck(:universe_membership_type).uniq
        types == [HopwaCaper::Service.sti_name]
      end
    end

    before { grant_project_access(user, hiv_role, [project], mode: :acl) }

    it 'redirects the HTML drilldown with the denial alert' do
      expect(cell).to be_present

      get hud_reports_hopwa_caper_question_cell_path(cell_path_args)

      expect(response).to redirect_to(result_path)
      expect(flash[:alert]).to eq(denial)
    end
  end

  context 'when the cell holds only service rows and the user can view HIV status on the service project' do
    let(:strmu_funder) { HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance') }
    let(:service_project) { create_hopwa_project(funder: strmu_funder) }
    let(:report) { create_report([project, service_project]) }
    let(:extra_rows) do
      create_enrolled_client_with_service(
        client_attrs: { first_name: 'Sam', last_name: 'Served' },
        project: service_project,
        entry_date: report_start_date,
      )
    end
    let(:cell) do
      report.report_cells.detect do |c|
        types = c.universe_members.pluck(:universe_membership_type).uniq
        types == [HopwaCaper::Service.sti_name]
      end
    end

    before { grant_project_access(user, hiv_role, [project, service_project], mode: :acl) }

    it 'renders the drilldown with the client' do
      expect(cell).to be_present

      get hud_reports_hopwa_caper_question_cell_path(cell_path_args)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Sam')
    end
  end

  context 'when the cell holds a restricted client and an unrestricted client' do
    let(:hidden_client) { create_client_with_warehouse_link(first_name: 'Hal', last_name: 'Hidden') }
    let(:extra_rows) do
      create_hiv_positive_enrollment(
        client: hidden_client,
        project: project,
        entry_date: report_start_date,
        household_id: Hmis::Hud::Base.generate_uuid,
        relationship_to_ho_h: 1,
      )
    end
    let(:hidden_row) { report.hopwa_caper_enrollments.find_by!(destination_client_id: hidden_client.destination_client.id) }
    let(:visible_row) { report.hopwa_caper_enrollments.where.not(id: hidden_row.id).first }
    let(:cell) { report.report_cells.detect { |c| c.universe_members.count == 2 } }

    before do
      grant_project_access(user, hiv_role, [project], mode: :acl)
      Hmis::Hud::Client.find(hidden_client.id).mark_as_restricted!(user: create(:hmis_user, data_source: data_source))
    end

    def client_link(row)
      /\/clients\/#{row.destination_client_id}(?!\d)/
    end

    def table_cell(value)
      />\s*#{Regexp.escape(value)}\s*</
    end

    def hidden_identifiers
      [hidden_row.personal_id, hidden_row.hmis_enrollment_id, hidden_row.destination_client_id.to_s]
    end

    def xlsx_values
      file = Tempfile.new(['drilldown', '.xlsx'])
      file.binmode
      file.write(response.body)
      file.close
      Roo::Excelx.new(file.path).sheet(0).to_a.flatten.compact.map(&:to_s)
    ensure
      file&.unlink
    end

    it 'renders the HTML drilldown without the restricted client identifiers or name' do
      expect(cell.universe_members.count).to eq(2)

      get hud_reports_hopwa_caper_question_cell_path(cell_path_args)

      expect(response).to have_http_status(:ok)
      hidden_identifiers.each { |value| expect(response.body).not_to match(table_cell(value)) }
      expect(response.body).not_to match(client_link(hidden_row))
      expect(response.body).not_to include('Hidden')
      expect(response.body).to include('Redacted')
    end

    it 'keeps identifiers and the client link for the unrestricted client' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args)

      expect(response.body).to include('Ann')
      expect(response.body).to match(table_cell(visible_row.personal_id))
      expect(response.body).to match(table_cell(visible_row.hmis_enrollment_id))
      expect(response.body).to match(client_link(visible_row))
    end

    it 'redacts the restricted client identifiers in the xlsx drilldown and keeps the others' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args.merge(format: :xlsx))

      expect(response).to have_http_status(:ok)
      values = xlsx_values
      expect(values).to include(visible_row.personal_id, visible_row.hmis_enrollment_id, visible_row.destination_client_id.to_s)
      expect(values & hidden_identifiers).to be_empty
      expect(values).to include('Redacted')
      expect(values).not_to include('Hal', 'Hidden')
    end
  end

  context 'when the cell holds only service rows for a restricted client' do
    let(:strmu_funder) { HudHelper.util('2026').funding_sources.invert.fetch('HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance') }
    let(:service_project) { create_hopwa_project(funder: strmu_funder) }
    let(:report) { create_report([project, service_project]) }
    let(:hidden_client) { create_client_with_warehouse_link(first_name: 'Hal', last_name: 'Hidden') }
    let(:extra_rows) do
      enrollment = create_hiv_positive_enrollment(
        client: hidden_client,
        project: service_project,
        entry_date: report_start_date,
        household_id: Hmis::Hud::Base.generate_uuid,
        relationship_to_ho_h: 1,
      )
      create(
        :hud_service,
        enrollment: enrollment,
        record_type: hopwa_financial_assistance,
        type_provided: rental_assistance,
        fa_amount: 100,
        date_provided: report_start_date,
        data_source: data_source,
      )
    end
    let(:hidden_row) { report.hopwa_caper_services.find_by!(destination_client_id: hidden_client.destination_client.id) }
    let(:cell) do
      report.report_cells.detect do |c|
        types = c.universe_members.pluck(:universe_membership_type).uniq
        types == [HopwaCaper::Service.sti_name]
      end
    end

    before do
      grant_project_access(user, hiv_role, [project, service_project], mode: :acl)
      Hmis::Hud::Client.find(hidden_client.id).mark_as_restricted!(user: create(:hmis_user, data_source: data_source))
    end

    it 'renders the drilldown without the client link or identifiers' do
      expect(cell.universe_members.count).to eq(1)

      get hud_reports_hopwa_caper_question_cell_path(cell_path_args)

      expect(response).to have_http_status(:ok)
      identifiers = [hidden_row.personal_id, hidden_row.hmis_enrollment_id, hidden_row.destination_client_id.to_s, hidden_row.service_id.to_s]
      identifiers.each { |value| expect(response.body).not_to match(/>\s*#{Regexp.escape(value)}\s*</) }
      expect(response.body).not_to match(/\/clients\/#{hidden_row.destination_client_id}(?!\d)/)
      expect(response.body).not_to include('Hidden')
      expect(response.body).to include('Redacted')
    end
  end

  context 'when the user cannot view HIV status on the project' do
    it 'redirects the HTML drilldown to the result page with the denial alert' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args)

      expect(response).to redirect_to(result_path)
      expect(flash[:alert]).to eq(denial)
    end

    it 'redirects the xlsx drilldown without sending a file' do
      get hud_reports_hopwa_caper_question_cell_path(cell_path_args.merge(format: :xlsx))

      expect(response).to redirect_to(result_path)
      expect(response.headers['Content-Disposition']).to be_nil
      expect(flash[:alert]).to eq(denial)
    end

    it 'omits drilldown links from the result page' do
      get result_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(hud_reports_hopwa_caper_question_cell_path(cell_path_args))
      expect(response.body).not_to include("/questions/#{question}/cells/")
    end
  end
end
