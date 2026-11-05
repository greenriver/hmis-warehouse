###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'InactiveClientReport::WarehouseReports::Reports', type: :request do
  include_context 'inactive client report fixtures'

  let!(:alpha) { create_report_client(first_name: 'Alpha', last_name: 'Aardvark') }
  let!(:beta) { create_report_client(first_name: 'Beta', last_name: 'Badger') }
  let(:params) { { filters: { on: on_date.to_s, project_ids: [project.id], require_service_during_range: 'false' } } }

  before { sign_in user }

  it 'renders the client count without loading processed service history' do
    processed_queries = []
    table = GrdaWarehouse::WarehouseClientsProcessed.quoted_table_name
    callback = ->(*, payload) { processed_queries << payload[:sql] if payload[:name] != 'SCHEMA' && payload[:sql].include?("FROM #{table}") }
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
      get inactive_client_report_warehouse_reports_reports_path, params: params
    end

    expect(response.body).to match(/hero-value-prs1[^>]*>2<\/div>/)
    expect(processed_queries).to eq([])
  end

  it 'computes activities only for the clients on the inline page' do
    stub_const('Pagy::DEFAULT', Pagy::DEFAULT.merge(items: 1))
    reports = []
    allow(InactiveClientReport::Report).to receive(:new).and_wrap_original do |original, *args|
      original.call(*args).tap { |report| reports << report }
    end

    get inactive_client_report_warehouse_reports_reports_path, params: params.merge(render_inline: '1', page: 2)

    expect(reports.last.activities[:entries].keys).to contain_exactly(beta.id)
    expect(response.body).to include('Badger')
    expect(response.body).not_to include('Aardvark')
  end
end
