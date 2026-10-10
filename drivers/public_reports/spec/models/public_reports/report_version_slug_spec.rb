###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::Report, type: :model do
  let(:report) do
    report = PublicReports::StateDashboard.new(user: create(:acl_user), filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } }, version_slug: 'state')
    report.save!(validate: false)
    report
  end

  def valid_with?(slug)
    report.version_slug = slug
    report.valid?
  end

  it 'allows a blank folder, which publishes at the root' do
    expect(valid_with?('')).to be(true)
  end

  it 'allows nested folders and rejects a leading, trailing or doubled slash' do
    expect(['coc/ma-500', '/state', 'state/', 'coc//ma-500'].map { |slug| valid_with?(slug) }).to eq([true, false, false, false])
  end

  it 'trims spaces around the folder before checking and saving it' do
    expect([report.update(version_slug: ' coc/ma-500  '), report.reload.version_slug]).to eq([true, 'coc/ma-500'])
  end

  it 'still saves a report whose folder was stored before the rule' do
    report.update_column(:version_slug, 'old folder')

    expect([report.update(state: 'published'), report.reload.state]).to eq([true, 'published'])
  end
end
