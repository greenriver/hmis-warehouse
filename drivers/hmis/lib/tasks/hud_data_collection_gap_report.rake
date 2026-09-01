# frozen_string_literal: true

# Reports HUD data that exists in the warehouse but would not be visible in HMIS,
# because no form patch enables the element carrying it for that project.
#
# Usage:
# rails driver:hmis:hud_data_collection_gap_report[2,2020-01-01,2026-08-31,tmp/gap_report.xlsx]
#
# The data source may be given as a name or an id.
desc 'Excel report of HUD data collected but not exposed by current form definitions'
task :hud_data_collection_gap_report, [:data_source, :start_date, :end_date, :output_path] => :environment do |_task, args|
  data_source = GrdaWarehouse::DataSource.find_by(id: args.data_source)
  if data_source.blank?
    puts "Data source not found: #{args.data_source}"
    exit 1
  end
  start_date = args.start_date.presence&.to_date || Date.new(2020, 1, 1)
  end_date = args.end_date.presence&.to_date || Date.current
  date_range = start_date..end_date
  output_path = args.output_path.presence || "tmp/hud_data_collection_gap_report_#{data_source.id}_#{Date.current.iso8601}.xlsx"

  result = HmisUtil::HudDataCollectionGapAnalyzer.new(
    data_source: data_source,
    date_range: date_range,
  ).perform

  HmisUtil::HudDataCollectionGapAnalyzer::ExcelReport.new(result: result).package.serialize(output_path)

  puts "Data source: #{data_source.name} (#{data_source.id})"
  puts "Window:      #{date_range.first} to #{date_range.last}"
  puts "Projects:    #{result.summary_rows.size}"
  puts "Field gaps:  #{result.field_gap_rows.size}"
  puts "Form gaps:   #{result.form_gap_rows.size}"
  puts "Written to:  #{output_path}"
  puts
  puts 'To retrieve this file via the warehouse UI (Account => Secure Files), run:'
  puts "  bundle exec rails secure_files:upload_to_secure_files[#{output_path},<your_user_id>]"
end
