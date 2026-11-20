###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContinuumSemiAnnualPerformance::DocumentExports::ReportPdfExport, type: :model do
  let(:report_class) { ContinuumSemiAnnualPerformance::EndOfYearReport }
  let(:report_definition_url) { 'continuum_semi_annual_performance/warehouse_reports/end_of_year_reports' }
  # The shared context defines `report_attributes` as {}, so each include re-declares it.
  it_behaves_like 'a document export limited to visible reports' do
    let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }
  end

  describe 'rendered html' do
    include_context 'report visibility users'
    let(:report_attributes) { { options: { coc_codes: ['XX-500'] }, completed_at: Time.current } }

    let(:apr_definition) { create(:touch_point_report, url: GrdaWarehouse::WarehouseReports::ReportDefinition.hud_url(:aprs), name: 'APR') }
    let(:assigns) { { report: own_report, tabs: [:summary, :es], title: own_report.title } }
    let(:controller_class) { own_report.class.controller_class }
    let(:html) do
      PdfGenerator.html(
        controller: controller_class,
        template: 'continuum_semi_annual_performance/warehouse_reports/reports/show_pdf',
        layout: 'layouts/performance_report',
        user: own_reports_user,
        assigns: assigns,
      )
    end
    # Same renderer PdfGenerator.html uses, but able to pass locals.
    let(:linked_tab_html) do
      controller_class.renderer.new(WardenProxyFactory.renderer_env(own_reports_user)).render(
        partial: 'continuum_semi_annual_performance/warehouse_reports/reports/tab_table',
        locals: { rows: own_report.rows_for(:es), links: true },
        assigns: assigns,
      )
    end

    before do
      # The viewer must be allowed to open the APR, otherwise links never render and the no-link check proves nothing.
      collection.set_viewables({ reports: [report_definition.id, apr_definition.id] })
      Rails.cache.clear
      hud = create(
        :hud_reports_report_instance,
        report_name: 'APR',
        user_id: own_reports_user.id,
        project_ids: [1],
        start_date: Date.new(2026, 1, 1),
        end_date: Date.new(2026, 12, 31),
      )
      hud.report_cells.create!(question: 'Q7a', cell_name: 'B6', universe: false, summary: 42)
      ContinuumSemiAnnualPerformance::CellSnapshot.new(report: own_report, project_type: :es, hud_report: hud).save!
    end

    it 'renders the drill-down link when links are on, so the no-link check can fail' do
      expect(linked_tab_html).to include('hud_reports/aprs')
    end

    it 'shows the snapshotted value in its row' do
      row = Nokogiri::HTML(html).css('tr').find { |tr| tr.at_css('td')&.text&.strip == 'Persons Served - Total' }

      expect(row.css('td').last.text.strip).to eq('42')
    end

    it 'renders no links in the tables' do
      body = Nokogiri::HTML(html).css('table')

      expect(body.css('a')).to be_empty
      expect(html).not_to include('hud_reports/aprs')
    end

    describe '#perform' do
      let(:captured_html) { [] }
      let(:pdf_file) { Tempfile.new(['coc_semi_annual', '.pdf']) }
      let(:pdf_generator) { instance_double(PdfGenerator) }

      before do
        allow(PdfGenerator).to receive(:html).and_wrap_original do |original, **args|
          original.call(**args).tap { |rendered| captured_html << rendered }
        end
        allow(PdfGenerator).to receive(:new).and_return(pdf_generator)
        allow(pdf_generator).to receive(:perform) { |&block| block.call(File.open(pdf_file.path)) }
      end

      it 'renders only the requested tab, without links' do
        export = described_class.new(user: own_reports_user, query_string: { id: own_report.id, tab: 'es' }.to_query)

        export.perform

        doc = Nokogiri::HTML(captured_html.fetch(0))
        expect(doc.css('h2').map { |h2| h2.text.strip }).to eq([ContinuumSemiAnnualPerformance::ReportsHelper.tab_title(:es)])
        expect(doc.css('table a')).to be_empty
        expect(pdf_generator).to have_received(:perform).once
      end
    end
  end
end
