###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# rubocop:disable Lint/UselessAssignment

selection = {
  report_start: Date.iso8601('2017-10-01'),
  report_end: Date.iso8601('2018-09-30'),
  data_source_ids: GrdaWarehouse::DataSource.where(short_name: 'SAMPLE').ids,
  coc_codes: ['XX-500'],
}

# Translate measure names to class names in FY2019 code base
measure_lookup = {
  'Measure 1' => 'MeasureOne',
  'Measure 2' => 'MeasureTwo',
  'Measure 3' => 'MeasureThree',
  'Measure 4' => 'MeasureFour',
  'Measure 5' => 'MeasureFive',
  'Measure 6' => 'MeasureSix',
  'Measure 7' => 'MeasureSeven',
}.freeze

diffs = []
questions = [
  'Measure 1',
  'Measure 2',
  'Measure 3',
  'Measure 4',
  'Measure 5',
  'Measure 6',
  'Measure 7',
]

puts "Running comparison of #{questions} between FY2020 and FY2019 code using #{selection}"

# handle some argument changes needed for 2020
s2020 = selection.dup
s2020[:start] = s2020.delete(:report_start)
s2020[:end] = s2020.delete(:report_end)
s2020[:user_id] = User.first.id

puts 'FY2020 building'
klass = HudSpmReport::Generators::Fy2020::Generator
generator = klass.new(
  ::HudReports::ReportInstance.from_filter(
    ::Filters::HudFilterBase.new(** s2020),
    klass.title,
    build_for_questions: questions,
  ),
)
generator.run!

fy2020 = generator.report
fy2020.reload
puts "FY2020 done\n\n#{fy2020.as_markdown}"

# Translate support keys in the FY2019 data into the table names in FY2020
table_lookup = {
  'onea' => '1a',
  'oneb' => '1b',
  'two' => '2',
  'three2' => '3.2',
  'four1' => '4.1',
  'four2' => '4.2',
  'four3' => '4.3',
  'four4' => '4.4',
  'four5' => '4.5',
  'four6' => '4.6',
  'five1' => '5.1',
  'five2' => '5.2',
  'sixab' => '6a.1 and 6b.1',
  'sixc1' => '6c.1',
  'sixc2' => '6c.2',
  'sevena1' => '7a.1',
  'sevenb1' => '7b.1',
  'sevenb2' => '7b.2',
}.freeze

questions.each do |question_name|
  puts "Generating #{question_name} using FY2019 code"

  code_name = measure_lookup.fetch(question_name)
  report_class = "Reports::SystemPerformance::Fy2019::#{code_name}".constantize
  generator_class = "ReportGenerators::SystemPerformance::Fy2019::#{code_name}".constantize

  report_name = "HUD System Performance FY 2019 - #{question_name}"
  report_type = report_class.where(name: report_name).first_or_create!

  fy2019 = ReportResult.create!(
    report: report_type,
    user: fy2020.user,
    percent_complete: 0, # this is an indication to the generator class that this needs to be run
    options: { project_group_ids: [], project_id: [] }.merge(selection), # aded defaults for formerly required params
  )

  # this is a confusing API! it picks up the most recent percent_complete: 0 ReportResult
  generator = generator_class.new({}).run!

  fy2019.reload

  if fy2019.percent_complete < 100 # rubocop:disable Style/GuardClause
    raise "FY2019 report did not complete successfully: #{fy2019.inspect}"
  else
    puts 'FY2019 done'
    fy2019.support.each do |key, info|
      old_value = fy2019.results[key]['value']
      next unless old_value.is_a?(Numeric)

      old_table, cell = *key.to_s.split('_', 2)
      cell = cell.upcase
      table = table_lookup.fetch(old_table)
      cell_info = {
        table: table,
        cell: cell,
        old_value: old_value,
        new_value: fy2020.answer(question: table, cell: cell).summary,
      }

      cell_info[:diff] = cell_info[:new_value].to_f - cell_info[:old_value].to_f
      next unless cell_info[:diff].abs.positive?

      old_ids = (info.dig('support', 'counts') || []).map(&:first).uniq
      # debugger if old_ids.size != cell_info[:new_value]
      new_ids = (fy2020.answer(question: table, cell: cell).members || []).map(&:client_id).uniq
      # GrdaWarehouse::Hud::Client.find
      # cell_info[:hud_client_ids_removed] = old_ids - new_ids
      # cell_info[:hud_client_ids_added] = new_ids - old_ids

      puts cell_info.to_json
      diffs << cell_info
    end
  end

  # fy2019.destroy
end

puts 'Success!!' if diffs.none?

# rubocop:enable Lint/UselessAssignment
