###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hud_enrollment_builders'
require 'support/shared_examples/report_visibility_examples'

RSpec.describe 'CoC semi-annual performance reports', type: :request, exclude_fixpoints: true do
  [
    [ContinuumSemiAnnualPerformance::MidYearReport, 'continuum_semi_annual_performance/warehouse_reports/mid_year_reports', :continuum_semi_annual_performance_warehouse_reports_mid_year_report_path, ['es', 'prevention', 'so', 'rrh']],
    [ContinuumSemiAnnualPerformance::EndOfYearReport, 'continuum_semi_annual_performance/warehouse_reports/end_of_year_reports', :continuum_semi_annual_performance_warehouse_reports_end_of_year_report_path, HudHelper.util.performance_reporting.keys.map(&:to_s)],
  ].each do |klass, url, path_helper, offered_project_types|
    describe klass.name do
      let(:report_class) { klass }
      let(:report_definition_url) { url }
      let(:report_path) { ->(report) { public_send(path_helper, report) } }
      let(:index_path) { public_send(path_helper.to_s.sub(/_report_path\z/, '_reports_path')) }

      it_behaves_like 'report member actions limited to visible reports' do
        let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }
      end

      describe 'approval' do
        include_context 'report visibility users'
        let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }

        before { sign_in(own_reports_user) }

        it 'records an approval on a report the user can see' do
          post "#{report_path.call(own_report)}/approval", params: { approved: '1' }

          expect(own_report.approvals.pluck(:user_id, :approved)).to eq([[own_reports_user.id, true]])
        end

        it 'records nothing when the submitted state matches the current state' do
          own_report.approve!(user: own_reports_user, approved: true)

          expect { post "#{report_path.call(own_report)}/approval", params: { approved: '1' } }.
            not_to change(own_report.approvals, :count)
          expect(response).to redirect_to(report_path.call(own_report))
        end

        it 'records an approval by a user who can view all reports on another user\'s report' do
          sign_in(all_reports_user)

          post "#{report_path.call(own_report)}/approval", params: { approved: '1' }

          expect(own_report.approvals.pluck(:user_id, :approved)).to eq([[all_reports_user.id, true]])
        end

        it 'returns not found and records nothing for a report the user cannot see' do
          post "#{report_path.call(others_report)}/approval", params: { approved: '1' }

          expect(response).to have_http_status(:not_found)
          expect(ContinuumSemiAnnualPerformance::Approval.where(report_instance_id: others_report.id)).not_to exist
        end
      end

      describe 'a purged report' do
        include_context 'report visibility users'
        let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }
        let(:cell_data) { { 'label' => 'Persons Served - Total', 'header' => false, 'format' => 'count', 'value' => 12.0, 'parts' => [] } }

        before do
          own_report.report_cells.create!(name: 'es.r1', universe: false, structured_data: cell_data)
          own_report.report_cells.create!(name: 'es.summary', universe: false, structured_data: { 'projects' => 1, 'persons' => 12, 'households' => 5 })
          Reports::ArchiveReportService.new(own_report).archive!
          own_report.hard_delete_archival_association(:report_cells)
          own_report.update_archival_metadata('purged_at', Time.current.iso8601)
          sign_in(own_reports_user)
        end

        it 'offers a reload and hides approval and downloads' do
          get report_path.call(own_report)

          expect(response).to have_http_status(:ok)
          doc = Nokogiri::HTML(response.body)
          expect(doc.css(%(form[action="#{report_path.call(own_report)}/reload_from_csv"] input[type=submit])).map { |i| i['value'] }).to eq(['Reload Report from Archived Data'])
          expect(doc.css(%(form[action$="/approval"]))).to be_empty
          expect(doc.css('#downloadButton')).to be_empty
        end

        it 'restores the cells and redirects to the report on reload' do
          post "#{report_path.call(own_report)}/reload_from_csv"

          expect(response).to redirect_to(report_path.call(own_report))
          own_report.reload
          expect(own_report.purged?).to be(false)
          expect(own_report.report_cells.pluck(:name)).to contain_exactly('es.r1', 'es.summary')
        end

        it 'returns not found and restores nothing for a report the user cannot see' do
          others_report.report_cells.create!(name: 'es.r1', universe: false, structured_data: cell_data)
          Reports::ArchiveReportService.new(others_report).archive!
          others_report.hard_delete_archival_association(:report_cells)
          others_report.update_archival_metadata('purged_at', Time.current.iso8601)

          post "#{report_path.call(others_report)}/reload_from_csv"

          expect(response).to have_http_status(:not_found)
          expect(others_report.reload.purged?).to be(true)
          expect(others_report.report_cells).to be_empty
        end

        it 'refuses approval and records nothing' do
          post "#{report_path.call(own_report)}/approval", params: { approved: '1' }

          expect(ContinuumSemiAnnualPerformance::Approval.where(report_instance_id: own_report.id)).not_to exist
        end
      end

      describe 'reloading a report that is not purged' do
        include_context 'report visibility users'
        let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }

        before { sign_in(own_reports_user) }

        it 'redirects to the report without calling the reload service' do
          allow(Reports::ReloadReportFromCsvService).to receive(:new)

          post "#{report_path.call(own_report)}/reload_from_csv"

          expect(response).to redirect_to(report_path.call(own_report))
          expect(Reports::ReloadReportFromCsvService).not_to have_received(:new)
        end
      end

      describe 'an unfinished report' do
        include_context 'report visibility users'
        let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }
        let(:hud_report) { create(:hud_reports_report_instance, report_name: 'Test APR', user_id: own_reports_user.id, project_ids: [1, 2]) }

        before do
          hud_report.report_cells.create!(question: 'Q7a', cell_name: 'B6', universe: false, summary: 42)
          ContinuumSemiAnnualPerformance::CellSnapshot.new(report: own_report, project_type: :es, hud_report: hud_report).save!
          sign_in(own_reports_user)
        end

        it 'shows Report Running and none of the values' do
          own_report.update!(completed_at: nil)

          get report_path.call(own_report), params: { tab: 'es' }

          expect(response.body).to include('Report Running')
          expect(response.body).not_to include('Persons Served - Total')
        end

        it 'shows Report Failed for a failed report' do
          own_report.update!(started_at: 1.hour.ago, completed_at: nil, failed_at: Time.current)

          get report_path.call(own_report), params: { tab: 'es' }

          expect(response.body).to include('Report Failed')
          expect(response.body).not_to include('Persons Served - Total')
        end

        it 'refuses approval and records nothing' do
          own_report.update!(completed_at: nil)

          post "#{report_path.call(own_report)}/approval", params: { approved: '1' }

          expect(ContinuumSemiAnnualPerformance::Approval.where(report_instance_id: own_report.id)).not_to exist
        end
      end

      describe 'showing a completed report' do
        include_context 'report visibility users'
        let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }
        let(:hud_report) { create(:hud_reports_report_instance, report_name: 'Test APR', user_id: own_reports_user.id, project_ids: [1, 2]) }
        let(:apr_definition) { create(:touch_point_report, url: GrdaWarehouse::WarehouseReports::ReportDefinition.hud_url(:aprs), name: 'APR') }
        let(:drilldown_link) do
          Rails.application.routes.url_helpers.hud_reports_apr_question_cell_path(apr_id: hud_report.id, question_id: 'Question 7', id: 'B6', table: 'Q7a')
        end

        before do
          hud_report.report_cells.create!(question: 'Q7a', cell_name: 'B6', universe: false, summary: 42)
          ContinuumSemiAnnualPerformance::CellSnapshot.new(report: own_report, project_type: :es, hud_report: hud_report).save!
        end

        def grant_apr_definition
          collection.set_viewables({ reports: [report_definition.id, apr_definition.id] })
          Rails.cache.clear
        end

        # The value cell of the row whose label cell matches, with whether that row holds a link.
        def value_row(label)
          row = Nokogiri::HTML(response.body).css('tr').find { |tr| tr.at_css('td')&.text&.strip == label }
          { value: row.css('td').last.text.strip, links: row.css('a').map { |a| a['href'] } }
        end

        def expect_unlinked_value
          expect(response).to have_http_status(:ok)
          expect(value_row('Persons Served - Total')).to eq(value: '42', links: [])
        end

        it 'links each cell to its drill-down and marks the table header' do
          grant_apr_definition
          sign_in(own_reports_user)

          get report_path.call(own_report), params: { tab: 'es' }

          expect(response.body).to include(%(href="#{drilldown_link}"))
          headers = Nokogiri::HTML(response.body).css('tr.table-active th').map { |th| th.text.strip }
          expect(headers).to include('Q7a: Number of Persons Served')
        end

        it 'shows the value without a link when the user lacks can_view_all_hud_reports and is not the sub-report owner' do
          grant_apr_definition
          sign_in(all_reports_user)

          get report_path.call(own_report), params: { tab: 'es' }

          expect_unlinked_value
        end

        it 'shows the value without a link when the APR definition is not assigned' do
          sign_in(own_reports_user)

          get report_path.call(own_report), params: { tab: 'es' }

          expect_unlinked_value
        end

        it 'shows the value without a link when the sub-report has been purged' do
          grant_apr_definition
          hud_report.update!(archival_metadata: { 'purged_at' => Time.current.iso8601 })
          sign_in(own_reports_user)

          get report_path.call(own_report), params: { tab: 'es' }

          expect_unlinked_value
        end

        it 'shows the value without a link when the sub-report has been deleted' do
          grant_apr_definition
          hud_report.destroy
          sign_in(own_reports_user)

          get report_path.call(own_report), params: { tab: 'es' }

          expect_unlinked_value
        end

        describe 'download links' do
          let(:excel_type) { 'ContinuumSemiAnnualPerformance::DocumentExports::ReportExcelExport' }
          let(:pdf_type) { 'ContinuumSemiAnnualPerformance::DocumentExports::ReportPdfExport' }
          let(:es_title) { ContinuumSemiAnnualPerformance::ReportsHelper.tab_title(:es) }

          before { sign_in(own_reports_user) }

          def download_links
            get report_path.call(own_report), params: { tab: 'es' }
            Nokogiri::HTML(response.body).css('a.j-document-exports').map do |a|
              { label: a.text.strip, url: a['data-url'], type: a['data-type'], query_string: a['data-query-string'] }
            end
          end

          it 'points every link at the document exports path with its type and report query' do
            expect(download_links).to eq(
              [
                { label: "Excel - #{es_title}", url: document_exports_path, type: excel_type, query_string: { id: own_report.id, tab: 'es' }.to_query },
                { label: 'Excel - Full CoC', url: document_exports_path, type: excel_type, query_string: { id: own_report.id, tab: 'all' }.to_query },
                { label: "PDF - #{es_title}", url: document_exports_path, type: pdf_type, query_string: { id: own_report.id, tab: 'es' }.to_query },
                { label: 'PDF - Full CoC', url: document_exports_path, type: pdf_type, query_string: { id: own_report.id, tab: 'all' }.to_query },
              ],
            )
          end

          it 'accepts a POST built from each link and queues the export for the owner' do
            download_links.each do |link|
              expect { post link[:url], params: { type: link[:type], query_string: link[:query_string] } }.
                to have_enqueued_job(DocumentExportJob)

              expect(response).to have_http_status(:ok)
              expect(response.parsed_body['status']).to eq(GrdaWarehouse::DocumentExport::PENDING_STATUS)
              expect(own_reports_user.document_exports.order(:id).last.type).to eq(link[:type])
            end
          end
        end

        it 'falls back to the summary tab for an unknown tab' do
          sign_in(own_reports_user)

          get report_path.call(own_report), params: { tab: 'bogus' }

          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Persons served')
          expect(response.body).not_to include('Persons Served - Total')
        end
      end

      describe 'the report list' do
        include_context 'report visibility users'
        let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }

        it 'links to the user own reports and not to another user\'s' do
          sign_in(own_reports_user)

          get index_path

          expect(response.body).to include(report_path.call(own_report))
          expect(response.body).not_to include(report_path.call(others_report))
        end

        it 'refuses a user whose collection does not hold the report definition' do
          user = create(:acl_user)
          setup_access_control(user, create(:role, name: 'unassigned', can_view_assigned_reports: true), create(:collection))
          sign_in(user)

          get index_path

          expect(response).to redirect_to(user.my_root_path)
          expect(response.body).not_to include(report_path.call(own_report))
        end

        def project_type_options(selector = 'option')
          Nokogiri::HTML(response.body).css("select[name=\"filters[project_type_codes][]\"] #{selector}").map { |o| o['value'] }.reject(&:blank?)
        end

        def selected_project_types
          project_type_options('option[selected]')
        end

        it 'offers only the project types the report uses' do
          sign_in(own_reports_user)

          get index_path

          expect(project_type_options).to match_array(offered_project_types)
        end

        it 'pre-selects every offered project type for a user with no previous report' do
          fresh_user = user_with_role(can_view_assigned_reports: true)
          sign_in(fresh_user)

          get index_path

          expect(report_class.where(user_id: fresh_user.id)).not_to exist
          expect(selected_project_types).to match_array(offered_project_types)
        end

        it 'pre-selects the project types of the previous report' do
          own_report.update!(options: { coc_codes: ['XX-500'], project_type_codes: ['rrh'] })
          sign_in(own_reports_user)

          get index_path

          expect(selected_project_types).to eq(['rrh'])
        end
      end
    end
  end

  describe 'creating a report' do
    include_context 'report visibility users'
    include_context 'HUD enrollment builders'
    let(:report_class) { ContinuumSemiAnnualPerformance::EndOfYearReport }
    let(:report_definition_url) { 'continuum_semi_annual_performance/warehouse_reports/end_of_year_reports' }
    let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }
    let(:project_type_codes) { HudHelper.util.performance_reporting.keys.map(&:to_s) }
    let(:params) { { filters: { start: '2026-01-01', end: '2026-12-31', coc_codes: coc_codes, project_type_codes: project_type_codes } } }

    before do
      projects = ['XX-500', 'XX-501'].map do |code|
        create(:lookup_coc, coc_code: code)
        create_project(project_type: 0, coc_code: code)
      end
      collection.set_viewables({ reports: [report_definition.id], projects: projects.map(&:id) })
      sign_in(own_reports_user)
    end

    context 'with one CoC' do
      let(:coc_codes) { ['XX-500'] }

      it 'saves the report and queues it' do
        expect { post continuum_semi_annual_performance_warehouse_reports_end_of_year_reports_path, params: params }.
          to have_enqueued_job(WarehouseReports::GenericReportJob).with(hash_including(report_class: 'ContinuumSemiAnnualPerformance::EndOfYearReport'))
        expect(report_class.order(:id).last.filter.coc_codes).to eq(['XX-500'])
      end
    end

    context 'with no projects selected' do
      let(:coc_codes) { ['XX-500'] }
      let(:project_type_codes) { [] }

      it 'saves nothing, queues nothing and shows the error' do
        expect { expect { post continuum_semi_annual_performance_warehouse_reports_end_of_year_reports_path, params: params }.not_to change(report_class, :count) }.
          not_to have_enqueued_job(WarehouseReports::GenericReportJob)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('must include at least one project')
      end
    end

    context 'with a Mid-Year report and only a Coordinated Entry project' do
      let(:report_class) { ContinuumSemiAnnualPerformance::MidYearReport }
      let(:report_definition_url) { 'continuum_semi_annual_performance/warehouse_reports/mid_year_reports' }
      let(:coc_codes) { ['XX-500'] }

      before do
        ce_project = create_project(project_type: 14, coc_code: 'XX-500')
        collection.set_viewables({ reports: [report_definition.id], projects: [ce_project.id] })
        Rails.cache.clear
      end

      it 'saves nothing, queues nothing and shows the error' do
        expect { expect { post continuum_semi_annual_performance_warehouse_reports_mid_year_reports_path, params: params }.not_to change(report_class, :count) }.
          not_to have_enqueued_job(WarehouseReports::GenericReportJob)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('must include at least one project')
      end
    end

    context 'with two CoCs' do
      let(:coc_codes) { ['XX-500', 'XX-501'] }

      it 'saves nothing and shows the error' do
        expect { post continuum_semi_annual_performance_warehouse_reports_end_of_year_reports_path, params: params }.not_to change(report_class, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('must include exactly one CoC')
      end
    end
  end
end

RSpec.describe 'CoC semi-annual performance report type routes', type: :request, exclude_fixpoints: true do
  include_context 'report visibility users'
  let(:report_class) { ContinuumSemiAnnualPerformance::MidYearReport }
  let(:report_definition_url) { 'continuum_semi_annual_performance/warehouse_reports/end_of_year_reports' }
  let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }

  before { sign_in(own_reports_user) }

  it 'returns not found for a Mid-Year report opened on the End of Year routes' do
    get continuum_semi_annual_performance_warehouse_reports_end_of_year_report_path(own_report)

    expect(response).to have_http_status(:not_found)
  end
end
