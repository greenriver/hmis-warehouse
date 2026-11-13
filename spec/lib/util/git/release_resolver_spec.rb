###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Git::ReleaseResolver do
  let(:revision) { 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }
  let(:repo) { 'greenriver/hmis-warehouse' }

  def stub_commits(shas)
    stub_request(:get, "https://api.github.com/repos/#{repo}/commits").
      with(query: { sha: revision, per_page: '50', page: '1' }).
      to_return(
        status: 200,
        body: shas.map { |sha| { sha: sha } }.to_json,
        headers: { 'Content-Type' => 'application/json' },
      )
  end

  def stub_tags(pairs, page: 1)
    stub_request(:get, "https://api.github.com/repos/#{repo}/tags").
      with(query: { per_page: '100', page: page.to_s }).
      to_return(
        status: 200,
        body: pairs.map { |name, sha| { name: name, commit: { sha: sha } } }.to_json,
        headers: { 'Content-Type' => 'application/json' },
      )
  end

  describe '.resolve' do
    it 'returns ahead: 0 when the deployed commit is the tagged commit' do
      stub_commits([revision, 'bbb', 'ccc'])
      stub_tags([['staging-release-222.0', revision]])

      expect(described_class.resolve(revision: revision)).
        to eq(tag: 'staging-release-222.0', ahead: 0, revision: revision)
    end

    it 'looks back past hot-fix commits to the nearest ancestor tag' do
      stub_commits([revision, 'hotfix2', 'hotfix1', 'tagged', 'older'])
      stub_tags([['staging-release-221.0', 'tagged']])

      expect(described_class.resolve(revision: revision)).
        to eq(tag: 'staging-release-221.0', ahead: 3, revision: revision)
    end

    # Both orderings are required. With only one, dropping the nearest-wins guard in
    # `resolve` degrades it to last-match-wins and the suite would stay green.
    it 'picks the nearest tag regardless of the order tags are returned in (far, then near)' do
      stub_commits([revision, 'near', 'far'])
      stub_tags([['staging-release-100.0', 'far'], ['staging-release-222.0', 'near']])

      expect(described_class.resolve(revision: revision)).
        to include(tag: 'staging-release-222.0', ahead: 1)
    end

    it 'picks the nearest tag regardless of the order tags are returned in (near, then far)' do
      stub_commits([revision, 'near', 'far'])
      stub_tags([['staging-release-222.0', 'near'], ['staging-release-100.0', 'far']])

      expect(described_class.resolve(revision: revision)).
        to include(tag: 'staging-release-222.0', ahead: 1)
    end

    it 'ignores tags that are not ancestors of the deployed commit' do
      stub_commits([revision, 'tagged'])
      stub_tags([['staging-release-999.0', 'unrelated-branch-sha'], ['staging-release-221.0', 'tagged']])

      expect(described_class.resolve(revision: revision)).
        to include(tag: 'staging-release-221.0', ahead: 1)
    end

    it 'returns nil when no tag is an ancestor of the deployed commit' do
      stub_commits([revision, 'bbb'])
      stub_tags([['staging-release-999.0', 'unrelated']])

      expect(described_class.resolve(revision: revision)).to be_nil
    end

    it 'does not find a tag beyond the lookback window' do
      stub_commits(50.times.map { |i| "c-#{i}" })
      stub_tags([['staging-release-200.0', 'c-50']])

      expect(described_class.resolve(revision: revision)).to be_nil
      expect(a_request(:get, "https://api.github.com/repos/#{repo}/commits").
        with(query: hash_including(page: '2'))).not_to have_been_made
    end

    it 'requests a second page of tags when the first page is full' do
      stub_commits([revision, 'tagged'])
      stub_tags(100.times.map { |i| ["staging-release-#{i}.0", "tag-sha-#{i}"] })
      stub_tags([['staging-release-200.0', 'tagged']], page: 2)

      expect(described_class.resolve(revision: revision)).
        to include(tag: 'staging-release-200.0', ahead: 1)
      expect(a_request(:get, "https://api.github.com/repos/#{repo}/tags").
        with(query: { per_page: '100', page: '3' })).not_to have_been_made
    end

    it 'does not request a second page of tags when the first comes back short' do
      stub_commits([revision])
      stub_tags([['staging-release-222.0', revision]])

      described_class.resolve(revision: revision)

      expect(a_request(:get, "https://api.github.com/repos/#{repo}/tags").
        with(query: hash_including(page: '2'))).not_to have_been_made
    end

    it 'returns nil when the revision is blank' do
      expect(described_class.resolve(revision: '')).to be_nil
      expect(described_class.resolve(revision: nil)).to be_nil
      expect(described_class.resolve(revision: 'unknown')).to be_nil
    end

    it 'returns nil on an API error status rather than raising' do
      stub_request(:get, /https:\/\/api\.github\.com\/repos\//).to_return(status: 403, body: '{}')

      expect(described_class.resolve(revision: revision)).to be_nil
    end

    it 'returns nil on a network timeout rather than raising' do
      stub_request(:get, /https:\/\/api\.github\.com\/repos\//).to_timeout

      expect(described_class.resolve(revision: revision)).to be_nil
    end

    it 'returns nil on unparseable JSON rather than raising' do
      stub_request(:get, /https:\/\/api\.github\.com\/repos\//).
        to_return(status: 200, body: 'not json', headers: { 'Content-Type' => 'application/json' })

      expect(described_class.resolve(revision: revision)).to be_nil
    end

    # A 200 whose body is an object rather than a list, which `get` rejects so the callers
    # never try to iterate it.
    it 'returns nil when the response body is not a list' do
      stub_request(:get, /https:\/\/api\.github\.com\/repos\//).
        to_return(status: 200, body: '{"message":"rate limited"}', headers: { 'Content-Type' => 'application/json' })

      expect(described_class.resolve(revision: revision)).to be_nil
    end
  end

  describe '.write_cache_file' do
    let(:path) { Rails.root.join('tmp', "git_release_spec_#{SecureRandom.hex(4)}.json").to_s }

    after { File.delete(path) if File.exist?(path) }

    it 'writes the resolved payload as JSON and returns true' do
      stub_commits([revision])
      stub_tags([['staging-release-222.0', revision]])

      expect(described_class.write_cache_file(revision: revision, path: path)).to be true
      expect(JSON.parse(File.read(path))).
        to eq('tag' => 'staging-release-222.0', 'ahead' => 0, 'revision' => revision)
    end

    it 'writes nothing and returns false when resolution fails' do
      stub_request(:get, /https:\/\/api\.github\.com\/repos\//).to_return(status: 403, body: '{}')

      expect(described_class.write_cache_file(revision: revision, path: path)).to be false
      expect(File.exist?(path)).to be false
    end

    it 'returns false rather than raising when the path is not writable' do
      stub_commits([revision])
      stub_tags([['staging-release-222.0', revision]])

      expect(described_class.write_cache_file(revision: revision, path: '/proc/nope/git_release.json')).to be false
    end
  end
end
