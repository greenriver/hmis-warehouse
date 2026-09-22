###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BackgroundRender::AccessLogsReportUsageJob do
  include Rails.application.routes.url_helpers

  let(:requesting_user) { create(:user) }
  let(:target_user) { create(:user, first_name: 'Jane', last_name: 'Doe') }
  let(:filters) { { start: 5.days.ago.to_date, end: Date.current }.to_json }

  def payload_from(html)
    node = Nokogiri::HTML5.fragment(html).at_css('[data-access-logs-usage-report-data-value]')
    JSON.parse(node['data-access-logs-usage-report-data-value'])
  end

  after { GrdaWarehouse::Config.invalidate_cache }
  before { Rails.cache.clear }

  it 'renders the usage-report content with a resolved report name and a linked user label' do
    ActivityLog.create!(
      user: target_user,
      path: '/warehouse_reports/chronic/1',
      controller_name: 'warehouse_reports',
      action_name: 'show',
      ip_address: '127.0.0.1',
      created_at: 1.day.ago,
    )

    payload = payload_from(described_class.new.render_html(filters: filters, user_id: requesting_user.id))

    report = payload['reports'].find { |r| r['key'] == 'warehouse_reports/chronic' }
    expect(report['name']).to eq('Potentially Chronic Clients')

    expect(payload['users'][target_user.id.to_s]).to eq(
      'label' => target_user.name_with_email,
      'edit_url' => edit_admin_user_path(target_user),
    )
  end

  it "omits a deleted user's id from the users directory while keeping their totals" do
    ActivityLog.create!(
      user: target_user,
      path: '/warehouse_reports/chronic/1',
      controller_name: 'warehouse_reports',
      action_name: 'show',
      ip_address: '127.0.0.1',
      created_at: 1.day.ago,
    )
    deleted_user_id = target_user.id
    target_user.destroy!

    payload = payload_from(described_class.new.render_html(filters: filters, user_id: requesting_user.id))

    expect(payload['user_totals']).to have_key(deleted_user_id.to_s)
    expect(payload['users']).not_to have_key(deleted_user_id.to_s)
  end
end
