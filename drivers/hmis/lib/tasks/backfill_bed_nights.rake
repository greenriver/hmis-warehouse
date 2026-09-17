# frozen_string_literal: true

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Backfill HUD bed-night services for every enrollment at the given HMIS projects.
# Companion to HmisCsvImporter::Aggregated::CombineEnrollments: after one-per-day
# enrollments are combined into a single stay, this fills in the nightly services.
#
# PROJECT_IDS is a comma-separated list of GrdaWarehouse::Hud::Project primary keys
# (the same ids the HMIS project pages use).
#
# Usage:
#   PROJECT_IDS=12,34 rails driver:hmis:backfill_bed_nights            # dry run (default)
#   PROJECT_IDS=12,34 rails driver:hmis:backfill_bed_nights[true]      # dry run
#   PROJECT_IDS=12,34 rails driver:hmis:backfill_bed_nights[false]     # apply
desc 'Backfill bed-night services for enrollments at PROJECT_IDS (dry_run defaults to true)'
task :backfill_bed_nights, [:dry_run] => [:environment] do |_task, args|
  raw_ids = ENV.fetch('PROJECT_IDS', '').split(',').map(&:strip).reject(&:blank?)
  raise 'PROJECT_IDS is required (comma-separated project ids)' if raw_ids.empty?
  raise 'PROJECT_IDS must be integers' unless raw_ids.all? { |id| id.match?(/\A\d+\z/) }

  dry_run = args[:dry_run].nil? || args[:dry_run].to_s == 'true'
  raise 'dry_run must be true or false' unless args[:dry_run].nil? || args[:dry_run].to_s.in?(['true', 'false'])

  HmisUtil::BedNightBackfill.new(project_pks: raw_ids.map(&:to_i), dry_run: dry_run).run!
end
