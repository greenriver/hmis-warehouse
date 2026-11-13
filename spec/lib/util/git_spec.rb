###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Git do
  let(:revision) { 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' }
  let(:cache_path) { Rails.root.join('tmp', "git_release_spec_#{SecureRandom.hex(4)}.json").to_s }

  before do
    described_class.reset_memo!
    allow(described_class).to receive(:revision).and_return(revision)
    stub_const('Git::ReleaseResolver::CACHE_PATH', cache_path)
    # Git.release returns nil in development; exercise the non-development path.
    allow(Rails.env).to receive(:development?).and_return(false)
  end

  after do
    described_class.reset_memo!
    File.delete(cache_path) if File.exist?(cache_path)
  end

  def write_cache(tag:, ahead:, rev: revision)
    File.write(cache_path, JSON.generate(tag: tag, ahead: ahead, revision: rev))
  end

  describe '.release' do
    it 'returns the resolved tag when the deployed commit is the tagged commit' do
      write_cache(tag: 'staging-release-222.0', ahead: 0)

      expect(described_class.release).to eq('staging-release-222.0')
    end

    it 'appends the ahead count for a hot-fix deploy' do
      write_cache(tag: 'staging-release-221.0', ahead: 25)

      expect(described_class.release).to eq('staging-release-221.0+25')
    end

    # No build-time fallback exists any more: a stale cache is worse than no badge,
    # since the build-time file named the *previous* release.
    it 'returns nil for a cache file computed for a different revision' do
      write_cache(tag: 'staging-release-100.0', ahead: 0, rev: 'some-other-sha')

      expect(described_class.release).to be_nil
    end

    it 'returns nil when no cache file exists' do
      expect(described_class.release).to be_nil
    end

    it 'returns nil for a cache file whose tag is empty' do
      write_cache(tag: '', ahead: 3)

      expect(described_class.release).to be_nil
    end

    it 'treats an ahead count arriving as a JSON string as a number' do
      File.write(cache_path, '{"tag":"staging-release-221.0","ahead":"25","revision":"' + revision + '"}')

      expect(described_class.release).to eq('staging-release-221.0+25')
    end

    it 'returns nil rather than raising on a corrupt cache file' do
      File.write(cache_path, 'not json')

      expect(described_class.release).to be_nil
    end

    it 'returns nil in development' do
      allow(Rails.env).to receive(:development?).and_return(true)
      write_cache(tag: 'staging-release-222.0', ahead: 0)

      expect(described_class.release).to be_nil
    end

    it 'reads the file only once per process' do
      write_cache(tag: 'staging-release-222.0', ahead: 0)

      expect(File).to receive(:read).with(cache_path).once.and_call_original

      3.times { described_class.release }
    end

    it 'memoizes the nil result too' do
      expect(described_class.release).to be_nil
      expect(File).not_to receive(:read)

      described_class.release
    end
  end

  describe '.release_details' do
    it 'reports the resolved tag and ahead count' do
      write_cache(tag: 'staging-release-221.0', ahead: 25)

      expect(described_class.release_details).
        to eq(tag: 'staging-release-221.0', ahead: 25)
    end

    it 'is nil when there is no release information' do
      expect(described_class.release_details).to be_nil
    end
  end
end
