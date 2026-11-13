###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Git
  def self.revision
    if Rails.env.development?
      `git rev-parse --short=9 HEAD`.chomp
    else
      File.read("#{Rails.root}/REVISION").chomp
    end
  rescue StandardError
    'unknown'
  end

  def self.branch
    if Rails.env.development?
      `git branch --no-color --show-current`.chomp
    else
      File.read("#{Rails.root}/GIT_BRANCH").chomp
    end
  rescue StandardError
    'unknown'
  end

  # Release this container is running, e.g. "staging-release-222.0", or
  # "staging-release-221.0+25" when 25 commits past that tag. nil when unknown.
  def self.release
    details = release_details
    return nil if details.nil?

    return details[:tag] if details[:ahead].zero?

    "#{details[:tag]}+#{details[:ahead]}"
  end

  # Reads the cache file Git::ReleaseResolver writes at container start. Returns
  # { tag:, ahead: }, or nil when the file is absent, unreadable, or was computed for a
  # different commit. Memoizes nil as well as a found value.
  def self.release_details
    return nil if Rails.env.development?
    return @release_details if defined?(@release_details)

    @release_details = resolved_release_details
  end

  # Test support only.
  def self.reset_memo!
    remove_instance_variable(:@release_details) if defined?(@release_details)
  end

  def self.resolved_release_details
    path = Git::ReleaseResolver::CACHE_PATH
    return nil unless File.exist?(path)

    details = JSON.parse(File.read(path))
    # Ignore a cache file computed for a different commit.
    return nil unless details['revision'].to_s == revision.to_s
    return nil if details['tag'].to_s.empty?

    { tag: details['tag'], ahead: details['ahead'].to_i }
  rescue StandardError
    nil
  end
end
