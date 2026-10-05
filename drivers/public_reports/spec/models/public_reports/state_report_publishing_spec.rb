###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Publishing the state-level reports', type: :model do
  let(:user) { create(:acl_user) }

  def published(klass)
    report = klass.new(user: user, filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } }, version_slug: 'state', published_url: 'https://example.test/index.html', state: 'published')
    report.save!(validate: false)
    report
  end

  it 'unpublishes the other state-level class at the same slug without changing its type' do
    old = published(PublicReports::StateLevelHomelessness)
    pit = published(PublicReports::PointInTime)
    dashboard = published(PublicReports::StateDashboard)
    allow(dashboard).to receive(:push_to_s3)
    allow(dashboard).to receive(:as_html).and_return('<html></html>')

    dashboard.publish!

    expect(
      [PublicReports::Report.find(old.id).attributes.values_at('type', 'published_url'), pit.reload.published_url],
    ).to eq([['PublicReports::StateLevelHomelessness', nil], 'https://example.test/index.html'])
  end

  it 'warns before publishing over the other state-level class' do
    old = published(PublicReports::StateLevelHomelessness)
    old.update_column(:completed_at, Time.zone.parse('2026-01-05'))
    dashboard = PublicReports::StateDashboard.new(version_slug: 'state')

    expect(dashboard.publish_warning).to include('Jan  5, 2026')
  end
end
