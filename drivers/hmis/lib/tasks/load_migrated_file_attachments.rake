# frozen_string_literal: true

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Load migrated client file attachments with HmisUtil::MigratedFileAttachmentLoader. Options are
# environment variables, all optional:
#   SOURCE_TABLE    schema-qualified *_file_attachments_to_load view or table
#                   (default HmisUtil::MigratedFileAttachmentLoader::DEFAULT_SOURCE_TABLE)
#   DRY_RUN         true or false (default true)
#   LIMIT           positive integer; caps the source rows a run examines (default no limit)
#   HEADSHOTS_ONLY  true or false; limits the run to client headshots (default false)
#
# Usage:
#   rails driver:hmis:load_migrated_file_attachments                                    # dry run, all rows
#   rails driver:hmis:load_migrated_file_attachments DRY_RUN=false LIMIT=25             # apply, at most 25 rows
#   rails driver:hmis:load_migrated_file_attachments DRY_RUN=false HEADSHOTS_ONLY=true  # apply, headshots only
desc 'Load migrated client file attachments (env: SOURCE_TABLE, DRY_RUN=true, LIMIT, HEADSHOTS_ONLY=false)'
task load_migrated_file_attachments: [:environment] do
  dry_run = ENV['DRY_RUN'].presence
  limit = ENV['LIMIT'].presence
  headshots_only = ENV['HEADSHOTS_ONLY'].presence
  raise 'DRY_RUN must be true or false' unless dry_run.nil? || dry_run.in?(['true', 'false'])
  raise 'LIMIT must be a positive integer' unless limit.nil? || limit.match?(/\A[1-9]\d*\z/)
  raise 'HEADSHOTS_ONLY must be true or false' unless headshots_only.nil? || headshots_only.in?(['true', 'false'])

  HmisUtil::MigratedFileAttachmentLoader.new(
    source_table: ENV.fetch('SOURCE_TABLE', HmisUtil::MigratedFileAttachmentLoader::DEFAULT_SOURCE_TABLE),
    dry_run: dry_run != 'false',
    limit: limit&.to_i,
    headshots_only: headshots_only == 'true',
  ).run!
end
