###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'performance_measurement/warehouse_reports/reports/_provider_comparisons', type: :view do
  let(:report) { instance_double(PerformanceMeasurement::Report, to_param: '1') }

  let(:system_data) do
    {
      es_average_bed_utilization: {
        decorator: 'success',
        display_value: '90%',
        goal_description: tooltip_markdown,
        tooltip: tooltip_markdown,
      },
    }
  end

  let(:project_data) do
    {
      1 => {
        project_name: 'Test Project',
        values: {
          es_average_bed_utilization: {
            decorator: 'success',
            display_value: '90%',
            tooltip: tooltip_markdown,
          },
        },
      },
    }
  end

  let(:table) do
    {
      headers: { es_average_bed_utilization: { title: 'Utilization', category: 'Bed Utilization' } },
      system: system_data,
      projects: project_data,
    }
  end

  let(:provider_comparison) do
    instance_double(
      PerformanceMeasurement::ProviderComparison,
      report: report,
      active_project_list: :my_projects,
      included_categories: { 'Emergency Shelters' => {} },
      table: table,
    )
  end

  before do
    assign(:provider_comparison, provider_comparison)
    allow(view).to receive(:can_view_projects?).and_return(false)
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render).with('chosen_universe').and_return('')
    allow(view).to receive(:render).with('report_tabs').and_return('')
  end

  def tooltip_nodes
    render partial: 'performance_measurement/warehouse_reports/reports/provider_comparisons'
    Nokogiri::HTML(rendered).css('td[data-bs-toggle="tooltip"]')
  end

  context 'when the tooltip markdown contains a literal HTML tag' do
    let(:tooltip_markdown) { '<img src=x onerror=alert(1)>' }

    it 'renders bs-title so a single entity decode still leaves it free of a literal angle bracket' do
      nodes = tooltip_nodes
      expect(nodes.size).to eq(2)
      nodes.each do |node|
        expect(node['data-bs-title']).not_to include('<')
      end
    end

    it 'writes bs-title double-escaped in the HTML source' do
      tooltip_nodes
      expect(rendered).to include(%(data-bs-title='&amp;lt;img src=x onerror=alert(1)&amp;gt;'))
    end

    it 'renders the sibling goal-description content as inert text after a single decode' do
      node = tooltip_nodes.first
      expect(node.children.map(&:name)).to eq(['text'])
      expect(node.text).to eq('<img src=x onerror=alert(1)>')
    end
  end

  context 'when the tooltip markdown is a benign bold phrase' do
    let(:tooltip_markdown) { '**10% annually**' }

    it 'renders bs-title so a single entity decode yields the intended tag' do
      nodes = tooltip_nodes
      expect(nodes.size).to eq(2)
      nodes.each do |node|
        expect(node['data-bs-title']).to eq('<strong>10% annually</strong>')
      end
    end

    it 'writes bs-title single-escaped, not double-escaped, in the HTML source' do
      tooltip_nodes
      expect(rendered).to include(%(data-bs-title='&lt;strong&gt;10% annually&lt;/strong&gt;'))
      expect(rendered).not_to include('&amp;lt;strong&amp;gt;')
    end
  end
end
