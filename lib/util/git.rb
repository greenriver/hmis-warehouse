###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

  def self.release
    # Release tags are only meaningful on deployed environments.
    # Development branches do not have a meaningful release tag.
    return 'release-DEV' if Rails.env.development?

    File.read("#{Rails.root}/GIT_RELEASE").chomp
  rescue StandardError
    'unknown'
  end
end
