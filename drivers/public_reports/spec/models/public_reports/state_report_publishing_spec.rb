###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Publishing the state-level reports', type: :model do
  let(:user) { create(:acl_user) }
  let(:precalculated_data) { File.read(Rails.root.join('spec/fixtures/files/public_reports/state_level_v2.json')) }
  let(:s3) do
    Aws::S3::Client.new(
      credentials: Aws::Credentials.new('key', 'secret'),
      region: 'us-east-1',
      stub_responses: { put_object: { etag: '"etag"' }, delete_object: { delete_marker: true } },
    )
  end

  before { allow(AwsS3).to receive(:new).and_return(instance_double(AwsS3, client: s3)) }

  def published(klass)
    report = klass.new(user: user, filter: { filters: { start: Date.parse('2024-01-01'), end: Date.parse('2025-12-31') } }, version_slug: 'state', published_url: 'https://example.test/index.html', state: 'published')
    report.save!(validate: false)
    report
  end

  it 'unpublishes the other state-level class at the same slug without changing its type' do
    old = published(PublicReports::StateLevelHomelessness)
    pit = published(PublicReports::PointInTime)
    dashboard = published(PublicReports::StateDashboard)

    dashboard.publish!

    expect(
      [PublicReports::Report.find(old.id).attributes.values_at('type', 'published_url'), pit.reload.published_url],
    ).to eq([['PublicReports::StateLevelHomelessness', nil], 'https://example.test/index.html'])
  end

  it 'uploads one public-read html object per section at the url each embed points to' do
    dashboard = published(PublicReports::StateDashboard)
    dashboard.update_column(:precalculated_data, precalculated_data)

    dashboard.publish!

    puts_by_key = s3.api_requests.select { |r| r[:operation_name] == :put_object }.to_h { |r| [r[:params][:key], r[:params]] }
    expected_keys = dashboard.sections.map { |section| URI(dashboard.generate_publish_url_for(section)).path.delete_prefix('/') }
    expect(puts_by_key.keys).to match_array(expected_keys)
    expect(puts_by_key.values.map { |p| p.values_at(:bucket, :acl, :content_type) }.uniq).to eq([['test', 'public-read', 'text/html']])

    dashboard.sections.zip(expected_keys).each do |section, key|
      body = puts_by_key.fetch(key)[:body]
      expect(body.scan('SECTION START').size).to eq(1), section.to_s
      expect(body).to include("<!-- SECTION START #{section} -->"), section.to_s
    end
    expect(puts_by_key.fetch(expected_keys[dashboard.sections.index(:pit)])[:body]).to include('chart--line')
    expect(dashboard.reload.attributes.values_at('published_url', 'state')).to eq([dashboard.generate_publish_url, 'published'])
  end

  it 'leaves the report and the one it would replace unchanged when an S3 upload fails' do
    old = published(PublicReports::StateLevelHomelessness)
    dashboard = published(PublicReports::StateDashboard)
    dashboard.update_columns(precalculated_data: precalculated_data, state: 'pre-calculated', published_url: nil)
    s3.stub_responses(:put_object, 'AccessDenied')

    expect { dashboard.publish! }.to raise_error(Aws::S3::Errors::AccessDenied)
    expect(
      [old.reload.attributes.values_at('published_url', 'state'), dashboard.reload.attributes.values_at('published_url', 'state')],
    ).to eq([['https://example.test/index.html', 'published'], [nil, 'pre-calculated']])
  end

  it 'removes every section object on unpublish' do
    dashboard = published(PublicReports::StateDashboard)

    dashboard.unpublish!

    deleted = s3.api_requests.select { |r| r[:operation_name] == :delete_object }.map { |r| [r[:params][:bucket], r[:params][:key]] }
    expect(deleted).to match_array(dashboard.sections.map { |section| ['test', URI(dashboard.generate_publish_url_for(section)).path.delete_prefix('/')] })
    expect(dashboard.reload.attributes.values_at('published_url', 'embed_code', 'html', 'state')).to eq([nil, nil, nil, 'pre-calculated'])
  end

  it 'warns before publishing over the other state-level class' do
    old = published(PublicReports::StateLevelHomelessness)
    old.update_column(:completed_at, Time.zone.parse('2026-01-05'))
    dashboard = PublicReports::StateDashboard.new(version_slug: 'state')

    expect(dashboard.publish_warning).to include('Jan  5, 2026')
  end

  it 'ignores a soft-deleted published row when warning' do
    published(PublicReports::StateLevelHomelessness).destroy
    dashboard = PublicReports::StateDashboard.new(version_slug: 'state')

    expect(dashboard.publish_warning).to be_nil
  end
end
