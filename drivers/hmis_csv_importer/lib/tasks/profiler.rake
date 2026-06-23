# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# rails driver:hmis_csv_importer:profile[/path/to/export/directory]
desc 'Profile a HUD HMIS CSV export and write metrics to docs/research/'
task :profile, [:dir] => [:environment] do |_, args|
  dir = args[:dir]
  raise ArgumentError, 'Usage: rails driver:hmis_csv_importer:profile[/path/to/export/dir]' if dir.blank?

  dir = File.expand_path(dir)
  raise ArgumentError, "Directory not found: #{dir}" unless Dir.exist?(dir)

  puts "Profiling HMIS CSV export at: #{dir}"
  print '  Analyzing (this may take a while for large exports)... '
  profiler = HmisCsvImporter::CsvProfiler.new(dir).run
  puts "done (export: #{profiler.export[:export_id]}, source: #{profiler.export[:source_id]}, #{profiler.export[:export_start_date]} - #{profiler.export[:export_end_date]})"

  export_id  = profiler.export[:export_id]
  source_id  = profiler.export[:source_id].presence
  dir_name   = ['hmis-csv', source_id, export_id].compact.join('-')
  output_dir = Rails.root.join('docs', 'research', dir_name).to_s

  puts "  Writing output to: #{output_dir}"
  HmisCsvImporter::CsvProfiler::ReportWriter.new(profiler, output_dir).write

  puts ''
  puts "Done. Results written to #{output_dir}/"
end
