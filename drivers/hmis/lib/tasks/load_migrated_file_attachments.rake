# frozen_string_literal: true

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Load migrated client file attachments with HmisUtil::MigratedFileAttachmentLoader.
#
# SOURCE_TABLE (optional) is the schema-qualified *_file_attachments_to_load view or table; it defaults
# to HmisUtil::MigratedFileAttachmentLoader::DEFAULT_SOURCE_TABLE. limit (optional) caps the source rows
# a run examines; a later run continues after them.
#
# Usage:
#   rails driver:hmis:load_migrated_file_attachments                  # dry run (default), all rows
#   rails "driver:hmis:load_migrated_file_attachments[false,25]"      # apply, at most 25 rows
#   SOURCE_TABLE=hmis_migration.mar_file_attachments_to_load rails "driver:hmis:load_migrated_file_attachments[false]"
desc 'Load migrated client file attachments from SOURCE_TABLE (dry_run defaults to true; optional row limit)'
task :load_migrated_file_attachments, [:dry_run, :limit] => [:environment] do |_task, args|
  raise 'dry_run must be true or false' unless args[:dry_run].nil? || args[:dry_run].to_s.in?(['true', 'false'])
  raise 'limit must be a positive integer' unless args[:limit].nil? || args[:limit].to_s.match?(/\A[1-9]\d*\z/)

  HmisUtil::MigratedFileAttachmentLoader.new(
    source_table: ENV.fetch('SOURCE_TABLE', HmisUtil::MigratedFileAttachmentLoader::DEFAULT_SOURCE_TABLE),
    dry_run: args[:dry_run].nil? || args[:dry_run].to_s == 'true',
    limit: args[:limit]&.to_i,
  ).run!
end
