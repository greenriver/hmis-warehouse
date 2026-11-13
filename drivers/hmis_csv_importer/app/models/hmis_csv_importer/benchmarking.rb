###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Benchmarking harness for the HMIS CSV importer. Runs datasets through the
# real import pipeline and records phase timing and per-file metrics so
# performance changes can be compared across branches and releases.
#
# Named Benchmarking (not Benchmark) to avoid shadowing Ruby's ::Benchmark,
# which the importer uses for phase timing.
module HmisCsvImporter::Benchmarking
  DEFAULT_RESULTS_DIR = 'var/benchmarks'

  # Benchmark runs seed, import, and (in later tooling) restore data
  # destructively; they must never run against a production database.
  def self.ensure_not_production!
    raise 'Refusing to run importer benchmarks in production' if Rails.env.production?
  end

  def self.results_dir
    Rails.root.join(DEFAULT_RESULTS_DIR).to_s
  end

  # Deployed environments (QA) run from images without a git checkout; these
  # identify the code version there instead of the git binary.
  GIT_SHA_ENV = 'HMIS_BENCHMARK_GIT_SHA'
  GIT_BRANCH_ENV = 'HMIS_BENCHMARK_GIT_BRANCH'

  def self.git_info
    sha = ENV[GIT_SHA_ENV].presence
    branch = ENV[GIT_BRANCH_ENV].presence
    return { sha: sha, branch: branch, dirty: nil } if sha || branch

    {
      sha: git_output('git rev-parse HEAD'),
      branch: git_output('git rev-parse --abbrev-ref HEAD'),
      dirty: git_output('git status --porcelain')&.present?,
    }
  end

  # Results are only comparable when attributable to a code version; refuse to
  # benchmark when neither git nor the env overrides can supply one.
  def self.git_identity!
    info = git_info
    return info if info[:sha].present? && info[:branch].present?

    raise "Cannot determine the code version for this benchmark run; git is unavailable or incomplete — set #{GIT_SHA_ENV} and #{GIT_BRANCH_ENV}"
  end

  def self.git_output(command)
    stdout, _stderr, status = Open3.capture3(command, chdir: Rails.root.to_s)
    return nil unless status.success?

    stdout.strip
  rescue SystemCallError
    nil
  end
end
