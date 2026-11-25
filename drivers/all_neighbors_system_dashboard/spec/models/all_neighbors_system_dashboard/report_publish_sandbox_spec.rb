###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AllNeighborsSystemDashboard::Report, type: :model do
  let(:report) { described_class.create!(user_id: User.system_user.id) }
  let!(:published_report) do
    report.published_reports.create!(
      user_id: User.system_user.id,
      path: report.path,
      published_url: 'https://example.test/report',
      state: :published,
    )
  end

  it 'refuses to publish in sandbox mode and leaves the published copy untouched' do
    with_sandbox_mode do
      expect { report.publish!(User.system_user.id) }.to raise_error(SandboxMode::IntegrationDisabled, 'Public report publishing is disabled in sandbox mode')
    end

    expect(published_report.reload.attributes.values_at('published_url', 'state')).to eq(['https://example.test/report', 'published'])
  end
end
