###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter::Benchmarking, type: :model do
  # Test design: Tier 2 — benchmark results must be attributable to a code
  # version. QA runs from images without a git checkout, so identity comes from
  # env overrides there; a run with neither git nor overrides must refuse.
  # The git binary is an external boundary, so its absence is simulated by
  # stubbing Open3 with the real error class.
  around do |example|
    original_sha = ENV.fetch(described_class::GIT_SHA_ENV, nil)
    original_branch = ENV.fetch(described_class::GIT_BRANCH_ENV, nil)
    ENV.delete(described_class::GIT_SHA_ENV)
    ENV.delete(described_class::GIT_BRANCH_ENV)
    example.run
  ensure
    [[described_class::GIT_SHA_ENV, original_sha], [described_class::GIT_BRANCH_ENV, original_branch]].each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  def stub_git_unavailable
    allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT, 'git')
  end

  describe '.git_info' do
    it 'prefers env overrides without shelling out' do
      ENV[described_class::GIT_SHA_ENV] = 'abc123'
      ENV[described_class::GIT_BRANCH_ENV] = 'qa-image'
      stub_git_unavailable

      expect(described_class.git_info).to eq(sha: 'abc123', branch: 'qa-image', dirty: nil)
    end

    it 'returns nils when git is unavailable and no overrides are set' do
      stub_git_unavailable

      expect(described_class.git_info).to eq(sha: nil, branch: nil, dirty: nil)
    end
  end

  describe '.git_identity!' do
    it 'returns the resolved identity when overrides are present' do
      ENV[described_class::GIT_SHA_ENV] = 'abc123'
      ENV[described_class::GIT_BRANCH_ENV] = 'qa-image'
      stub_git_unavailable

      expect(described_class.git_identity!).to eq(sha: 'abc123', branch: 'qa-image', dirty: nil)
    end

    it 'raises with instructions when git is unavailable and no overrides are set' do
      stub_git_unavailable

      expect { described_class.git_identity! }.to raise_error(/HMIS_BENCHMARK_GIT_SHA/)
    end

    it 'raises when only the sha override is set' do
      ENV[described_class::GIT_SHA_ENV] = 'abc123'
      stub_git_unavailable

      expect { described_class.git_identity! }.to raise_error(/HMIS_BENCHMARK_GIT_BRANCH/)
    end
  end
end
