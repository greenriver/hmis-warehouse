###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'nokogiri'
require_relative '../../models/filters/criteria/shared_filter_criteria_context'

RSpec.describe BackgroundRender::ActiveClientsReportJob do
  include_context 'filter criteria setup'

  let(:filter_params) do
    {
      start: Date.new(2023, 1, 1),
      end: Date.new(2023, 12, 31),
      project_type_codes: ['es'],
      sub_population: 'clients',
    }
  end
  let(:role) do
    create(:role, can_view_clients: true, can_view_all_reports: true, can_view_assigned_reports: true)
  end

  let!(:matching_enrollment) do
    create_enrollment_for_client(
      create(:grda_warehouse_hud_client),
      date: filter_params[:start] + 5.days,
      first_date_in_program: filter_params[:start] + 5.days,
      last_date_in_program: filter_params[:end] - 5.days,
      project_type: 1,
    )
  end
  let!(:outside_date_range_enrollment) do
    create_enrollment_for_client(
      create(:grda_warehouse_hud_client),
      date: filter_params[:start] - 30.days,
      first_date_in_program: filter_params[:start] - 30.days,
      last_date_in_program: filter_params[:start] - 1.day,
      project_type: 1,
    )
  end

  before do
    [matching_enrollment, outside_date_range_enrollment].each do |enrollment|
      create(
        :service_history_service,
        service_history_enrollment: enrollment,
        record_type: 200,
        date: enrollment.first_date_in_program + 1.day,
        client_id: enrollment.client_id,
        project_type: enrollment.project_type,
      )
    end
  end

  def render_report(params = filter_params, page: nil)
    html = described_class.new.render_html(filter: { filters: params }.to_json, user_id: user.id, page: page)
    Nokogiri::HTML5.fragment(html)
  end

  context 'with one row per page' do
    around do |example|
      items = Pagy::DEFAULT[:items]
      Pagy::DEFAULT[:items] = 1
      example.run
    ensure
      Pagy::DEFAULT[:items] = items
    end

    let!(:later_enrollment) do
      create_enrollment_for_client(
        create(:grda_warehouse_hud_client),
        date: filter_params[:start] + 20.days,
        first_date_in_program: filter_params[:start] + 20.days,
        last_date_in_program: filter_params[:end] - 5.days,
        project_type: 1,
      )
    end

    before do
      create(:service_history_service, service_history_enrollment: later_enrollment, record_type: 200, date: later_enrollment.first_date_in_program + 1.day, client_id: later_enrollment.client_id, project_type: 1)
    end

    it 'renders the requested page with page links that keep the filters' do
      params = filter_params.merge(project_type_codes: ['es', 'so'])
      doc = render_report(params, page: '2')

      expect(doc.css('tbody tr td').map(&:text)).to include(later_enrollment.first_date_in_program.to_s)
      page_one_href = doc.css('a[href*="client_details/actives"]').map { |a| a['href'] }.detect { |href| href.include?('page=1') }
      link_filter = Rack::Utils.parse_nested_query(URI(page_one_href).query)['filter']
      expect(link_filter).to include('start' => filter_params[:start].iso8601, 'project_type_codes' => ['es', 'so'])
      expect(link_filter.keys - ClientDetailReports.permitted_filter_keys.map(&:to_s)).to eq([])
    end
  end

  it 'renders the counts and only the in-range enrollment, linked to the client' do
    doc = render_report

    expect(doc.text).to include('1 clients with 1 enrollments')
    expect(doc.css('tbody tr').size).to eq(1)
    expect(doc.css('tbody a[href*="/clients/"]').size).to eq(1)
  end

  it 'keeps a multi-year range instead of clamping it to one year' do
    doc = render_report(filter_params.merge(start: Date.new(2021, 1, 1)))

    expect(doc.text).to include("between #{Date.new(2021, 1, 1)} and #{filter_params[:end]}")
  end

  it 'loads projects without a query per row' do
    project_query_count = lambda do
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] if payload[:sql].match?(/FROM "Project"/) }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { render_report }
      queries.size
    end

    baseline = project_query_count.call
    2.times do
      extra = create_enrollment_for_client(
        create(:grda_warehouse_hud_client),
        project_id: create_project.ProjectID,
        date: filter_params[:start] + 5.days,
        first_date_in_program: filter_params[:start] + 5.days,
        last_date_in_program: filter_params[:end] - 5.days,
        project_type: 1,
      )
      create(:service_history_service, service_history_enrollment: extra, record_type: 200, date: extra.first_date_in_program + 1.day, client_id: extra.client_id, project_type: 1)
    end

    expect(render_report.css('tbody tr').size).to eq(3)
    expect(project_query_count.call).to eq(baseline)
  end

  context 'when the user cannot view clients' do
    let(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true) }

    it 'shows names without client links' do
      doc = render_report

      expect(doc.css('tbody tr').size).to eq(1)
      expect(doc.css('tbody a[href*="/clients/"]')).to be_empty
    end
  end
end
