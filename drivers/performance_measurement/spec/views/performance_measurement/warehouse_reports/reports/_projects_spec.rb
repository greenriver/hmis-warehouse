###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'performance_measurement/warehouse_reports/reports/_projects', type: :view do
  let(:note) { 'Project-level charts are left out of PDFs for reports with more than 200 projects.' }
  let(:hud_project) { double('hud_project') }
  let(:project_result) { double('project_result', hud_project: hud_project, percentage?: false) }
  let(:key_result) { double('key_result', data_for_projects_bar: {}, primary_unit: '%') }
  let(:report) do
    instance_double(
      PerformanceMeasurement::Report,
      result_for: key_result,
      highlight_id: 1,
      filter: double('filter', date_range_words: 'Jan 1 - Dec 31'),
      my_projects: { 1 => project_result },
      other_projects: { 2 => project_result },
      project_charts_in_pdf?: charts_in_pdf,
    )
  end

  before do
    assign(:report, report)
    allow(hud_project).to receive(:name).with(anything, include_project_type: true).and_return('Project A')
    allow(view).to receive(:current_user).and_return(build_stubbed(:user))
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render).with('performance_measurement/warehouse_reports/reports/static_spm_warning').and_return('')
    allow(view).to receive(:render).with(
      'performance_measurement/warehouse_reports/reports/details_row',
      hash_including(:class_name),
    ) { |_, locals| "ROW:#{locals[:class_name]}" }
  end

  def render_partial(pdf:)
    render partial: 'performance_measurement/warehouse_reports/reports/projects', locals: { key: :key, category: 'Cat', pdf: pdf }
    Nokogiri::HTML(rendered)
  end

  context 'when rendering a PDF for a report over the project limit' do
    let(:charts_in_pdf) { false }

    it 'replaces per-project charts with a note' do
      doc = render_partial(pdf: true)

      expect(rendered).not_to include('ROW:jProjectLevelPerformance_')
      expect(rendered).to include(note)
      expect(doc.css('#jAppProjectChart_key').size).to eq(1)
      expect(report).not_to have_received(:my_projects)
      expect(report).not_to have_received(:other_projects)
    end
  end

  context 'when rendering a PDF for a report within the project limit' do
    let(:charts_in_pdf) { true }

    it 'renders a chart for each project' do
      render_partial(pdf: true)

      expect(rendered).to include('ROW:jProjectLevelPerformance_key_1')
      expect(rendered).to include('ROW:jProjectLevelPerformance_key_2')
      expect(rendered).not_to include(note)
    end
  end

  context 'when rendering the web page for a report over the project limit' do
    let(:charts_in_pdf) { false }

    it 'keeps per-project charts on the web page' do
      render_partial(pdf: false)

      expect(rendered).to include('ROW:jProjectLevelPerformance_key_1')
      expect(rendered).to include('ROW:jProjectLevelPerformance_key_2')
      expect(rendered).not_to include(note)
    end
  end
end
