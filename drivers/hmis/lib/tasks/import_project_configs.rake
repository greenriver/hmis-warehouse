# frozen_string_literal: true

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Import project-level Hmis::ProjectConfig records from a CSV.
#
# Prefer org-level or project-type-level rules when possible.
#
# Usage:
#   rails driver:hmis:import_project_configs[/path/to/file.csv]                    # dry run (default)
#   rails driver:hmis:import_project_configs[/path/to/file.csv,true]               # dry run
#   rails driver:hmis:import_project_configs[/path/to/file.csv,false]              # apply
#   rails driver:hmis:import_project_configs[/path/to/file.csv,false,123]          # apply for data source 123
#   rails driver:hmis:import_project_configs[/path/to/file.csv,false,123,true]     # skip missing ProjectIDs
desc 'Import project-level ProjectConfig records from a CSV (dry_run defaults to true)'
task :import_project_configs, [:csv, :dry_run, :data_source_id, :skip_projects_not_found] => [:environment] do |_task, args|
  raise 'csv path is required' if args[:csv].blank?

  dry_run = args[:dry_run].nil? || args[:dry_run].to_s == 'true'
  raise 'dry_run must be true or false' unless args[:dry_run].nil? || args[:dry_run].to_s.in?(['true', 'false'])

  skip_projects_not_found = args[:skip_projects_not_found].to_s == 'true'
  raise 'skip_projects_not_found must be true or false' unless args[:skip_projects_not_found].nil? || args[:skip_projects_not_found].to_s.in?(['true', 'false'])

  data_source_id = args[:data_source_id].presence

  HmisUtil::HmisProjectConfigImporter.new(
    csv_path: args[:csv],
    data_source_id: data_source_id,
    dry_run: dry_run,
    skip_projects_not_found: skip_projects_not_found,
  ).run!
end
