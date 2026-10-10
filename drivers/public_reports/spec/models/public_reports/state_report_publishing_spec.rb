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
  let(:section_keys) do
    ['pit', 'entering_exiting', 'summary', 'map', 'who', 'race', 'raw'].map { |section| "state-level-homelessness/state/#{section}/index.html" }
  end

  around { |example| travel_to(Time.zone.parse('2026-10-10 12:00')) { example.run } }

  let(:staging_keys) do
    ['pit', 'entering_exiting', 'summary', 'map', 'who', 'race', 'raw'].map { |section| "state-level-homelessness/_staging_2026-10-10/state/#{section}/index.html" }
  end

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

  it 'keeps a state-level report published in a different folder' do
    coc = published(PublicReports::StateLevelHomelessness)
    coc.update_column(:version_slug, 'coc-500')
    dashboard = published(PublicReports::StateDashboard)

    dashboard.publish!

    expect(coc.reload.attributes.values_at('published_url', 'state')).to eq(['https://example.test/index.html', 'published'])
  end

  it 'stages each section privately, copies it public to the url its embed points to, then deletes the staged copy' do
    dashboard = published(PublicReports::StateDashboard)
    dashboard.update_column(:precalculated_data, precalculated_data)

    dashboard.publish!

    requests = s3.api_requests.map { |r| [r[:operation_name], r[:params]] }
    puts_by_key = requests.select { |op, _| op == :put_object }.to_h { |_, p| [p[:key], p] }
    expect(requests.map(&:first)).to eq([:put_object] * 7 + [:copy_object] * 7 + [:delete_object] * 7)
    expect(puts_by_key.keys).to match_array(staging_keys)
    expect(puts_by_key.values.map { |p| p.values_at(:bucket, :acl, :content_type) }.uniq).to eq([['test', nil, 'text/html']])
    expect(requests.select { |op, _| op == :copy_object }.map { |_, p| p.values_at(:copy_source, :key, :acl) }).to match_array(staging_keys.zip(section_keys).map { |staged, key| ["test/#{staged}", key, 'public-read'] })
    expect(requests.select { |op, _| op == :delete_object }.map { |_, p| p[:key] }).to match_array(staging_keys)

    dashboard.sections.zip(staging_keys).each do |section, key|
      body = puts_by_key.fetch(key)[:body]
      expect(body.scan('SECTION START').size).to eq(1), section.to_s
      expect(body).to include("<!-- SECTION START #{section} -->"), section.to_s
    end
    expect(puts_by_key.fetch(staging_keys[dashboard.sections.index(:pit)])[:body]).to include('chart--line')
    expect(dashboard.reload.attributes.values_at('published_url', 'state')).to eq([dashboard.generate_publish_url, 'published'])
  end

  it 'touches no public page and leaves both reports unchanged when a staging upload fails' do
    old = published(PublicReports::StateLevelHomelessness)
    dashboard = published(PublicReports::StateDashboard)
    dashboard.update_columns(precalculated_data: precalculated_data, state: 'pre-calculated', published_url: nil)
    calls = 0
    s3.stub_responses(:put_object, ->(_context) { (calls += 1) == 3 ? 'ServiceUnavailable' : { etag: '"etag"' } })

    expect { dashboard.publish! }.to raise_error(Aws::S3::Errors::ServiceUnavailable)
    expect(s3.api_requests.map { |r| r[:params][:key] } & section_keys).to eq([])
    expect(
      [old.reload.attributes.values_at('published_url', 'state'), dashboard.reload.attributes.values_at('published_url', 'state')],
    ).to eq([['https://example.test/index.html', 'published'], [nil, 'pre-calculated']])
  end

  it 'removes every section object on unpublish' do
    dashboard = published(PublicReports::StateDashboard)

    dashboard.unpublish!

    deleted = s3.api_requests.select { |r| r[:operation_name] == :delete_object }.map { |r| [r[:params][:bucket], r[:params][:key]] }
    expect(deleted).to match_array(section_keys.map { |key| ['test', key] })
    expect(dashboard.reload.attributes.values_at('published_url', 'embed_code', 'html', 'state')).to eq([nil, nil, nil, 'pre-calculated'])
  end

  it 'publishes each section at the url the legacy state-level report used' do
    legacy = PublicReports::StateLevelHomelessness.new(version_slug: 'state')
    dashboard = PublicReports::StateDashboard.new(version_slug: 'state')

    expect(dashboard.sections.map { |s| dashboard.generate_publish_url_for(s) }).to eq(legacy.sections.map { |s| legacy.generate_publish_url_for(s) })
  end

  it 'publishes a nested folder at the path its embed url points to' do
    dashboard = published(PublicReports::StateDashboard)
    dashboard.update_columns(precalculated_data: precalculated_data, version_slug: 'coc/ma-500')

    dashboard.publish!

    copied = s3.api_requests.select { |r| r[:operation_name] == :copy_object }.map { |r| r[:params][:key] }
    url_paths = dashboard.sections.map { |section| dashboard.generate_publish_url_for(section)[%r{state-level-homelessness/.+\z}] }
    expect(copied).to eq(url_paths)
    expect(copied.first).to eq('state-level-homelessness/coc/ma-500/pit/index.html')
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
