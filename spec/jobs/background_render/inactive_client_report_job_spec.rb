###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackgroundRender::InactiveClientReportJob, type: :model do
  include_context 'inactive client report fixtures'

  let!(:alpha) { create_report_client(first_name: 'Alpha', last_name: 'Aardvark') }
  let!(:beta) { create_report_client(first_name: 'Beta', last_name: 'Badger') }
  let(:filters_json) { { on: on_date.to_s, project_ids: [project.id], require_service_during_range: 'false' }.to_json }
  let(:reports) { [] }

  before do
    stub_const('Pagy::DEFAULT', Pagy::DEFAULT.merge(items: 1))
    allow(InactiveClientReport::Report).to receive(:new).and_wrap_original do |original, *args|
      original.call(*args).tap { |report| reports << report }
    end
  end

  it 'computes most-recent entry dates only for clients on the requested page' do
    html = described_class.new.render_html(filters: filters_json, user_id: user.id, page: 2)

    expect(reports.last.activities[:entries].keys).to contain_exactly(beta.id)
    expect(html).to include('Badger')
    expect(html).not_to include('Aardvark')
  end

  it 'counts every client in the report total' do
    described_class.new.render_html(filters: filters_json, user_id: user.id, page: 1)

    expect(reports.last.total_client_count).to eq(2)
  end
end
