# Import AC HMIS scoring rules from two CSVs: a Variable Definitions file and a Variable Weights file.
#
# Usage:
#   rails driver:hmis:import_ac_hmis_scoring_rules_20250812[hna_2] \
#     VARIABLE_DEFINITIONS_CSV="/path/to/scoring_variable_definitions.csv" \
#     VARIABLE_WEIGHTS_CSV="/path/to/scoring_variable_weights.csv"
#   rails "driver:hmis:import_ac_hmis_scoring_rules[custom_form_id]" # quotes needed for special chars
#
# Notes:
# - If ENV paths are not provided, defaults will look for files at:
#     Rails.root.join('scoring_variable_definitions.csv')
#     Rails.root.join('scoring_variable_weights.csv')
#   (Pass explicit ENV paths if your files are named differently.)
# - Skips rows it cannot process and logs why.
# - form_definition_identifier argument is required.
#
# Minimal CSV examples:
#
# scoring_variable_definitions.csv
#   variable_name,link_ids,match_value,include,gt,gte,lt,lte
#   question_a_6_or_more_times,field_a,6 or more times,,,,
#   question_b_numeric_value,, , , , , , # blank criteria columns treated as value type
#   question_c_range_check,field_b,,,,20,,24
#   question_f_missing_data,field_f,<null>,,,,, # exact_match against nil
#
# scoring_variable_weights.csv
#   ALGORITHM_ID,VARIABLE_NAME,VARIABLE_WEIGHT
#   12,question_a_6_or_more_times,0.5
#   13,question_b_response_type,0.7
#   14,INTERCEPT,-0.4

require 'csv'

desc 'Import AC HMIS scoring rules from variable weights and variables CSVs'
task :import_ac_hmis_scoring_rules_20250812, [:form_definition_identifier] => [:environment] do |_task, args|
  form_definition_identifier = args[:form_definition_identifier]
  if form_definition_identifier.blank?
    puts 'ERROR: form_definition_identifier argument is required'
    puts 'Usage: rails driver:hmis:import_ac_hmis_scoring_rules[form_id]'
    abort
  end

  variable_definitions_path = ENV['VARIABLE_DEFINITIONS_CSV'] || Rails.root.join('scoring_variable_definitions.csv').to_s
  var_weights_path = ENV['VARIABLE_WEIGHTS_CSV'] || Rails.root.join('scoring_variable_weights.csv').to_s

  puts "Form Definition Identifier: #{form_definition_identifier}"
  puts "Reading Variable Definitions CSV: #{variable_definitions_path}"
  puts "Reading Variable Weights CSV: #{var_weights_path}"

  unless File.exist?(variable_definitions_path)
    puts "ERROR: Variable Definitions CSV not found at #{variable_definitions_path}"
    abort
  end

  unless File.exist?(var_weights_path)
    puts "ERROR: Variable Weights CSV not found at #{var_weights_path}"
    abort
  end

  # Build lookup: variable_name (stripped) => row hash
  definitions_by_variable_name = {}
  CSV.foreach(variable_definitions_path, headers: true) do |row|
    variable_name = (row['variable_name'] || '').strip
    next if variable_name.empty?

    definitions_by_variable_name[variable_name] = row.to_h
  end

  # Algorithm mapping per instruction
  algorithm_map = {
    '12' => 'alt_aha_1',
    '14' => 'alt_aha_2',
    '13' => 'alt_aha_3',
  }

  created_count = 0
  skipped_count = 0

  # Iterate variable weights rows
  CSV.foreach(var_weights_path, headers: true) do |row|
    variable_name_raw = row['VARIABLE_NAME']
    algorithm_id = row['ALGORITHM_ID']
    weight_value = row['VARIABLE_WEIGHT']

    if variable_name_raw.nil?
      puts 'SKIP: VARIABLE_NAME missing in weights row'
      skipped_count += 1
      next
    end

    variable_name = variable_name_raw.strip
    if variable_name.casecmp('INTERCEPT').zero?
      # Skip intercept weights
      next
    end

    algorithm = algorithm_map[algorithm_id.to_s]
    if algorithm.nil?
      puts "SKIP: Unknown ALGORITHM_ID=#{algorithm_id.inspect} for VARIABLE_NAME=#{variable_name}"
      skipped_count += 1
      next
    end

    definition_row = definitions_by_variable_name[variable_name]
    if definition_row.nil?
      puts "SKIP: No Variable Definitions row found for VARIABLE_NAME=#{variable_name}"
      skipped_count += 1
      next
    end

    link_ids_cell = definition_row['link_ids']
    if link_ids_cell.nil? || link_ids_cell.strip.empty?
      puts "SKIP: No link_ids for VARIABLE_NAME=#{variable_name}"
      skipped_count += 1
      next
    end

    link_ids = link_ids_cell.split(',').map { |s| s.strip }.reject(&:empty?)
    if link_ids.empty?
      puts "SKIP: Parsed empty link_ids for VARIABLE_NAME=#{variable_name} (raw=#{link_ids_cell.inspect})"
      skipped_count += 1
      next
    end

    # Determine criteria_type and criteria_config
    criteria_type, criteria_config = determine_criteria(definition_row)
    if criteria_type.nil?
      puts "SKIP: Could not determine criteria for VARIABLE_NAME=#{variable_name}"
      skipped_count += 1
      next
    end

    link_ids.each do |link_id|
      Hmis::Scoring::Rule.create!(
        link_id: link_id,
        form_definition_identifier: form_definition_identifier,
        algorithm: algorithm,
        criteria_type: criteria_type,
        criteria_config: criteria_config,
        weight: weight_value,
        variable_name: variable_name,
      )
      created_count += 1
    rescue StandardError => e
      puts "SKIP: Failed to create rule for VARIABLE_NAME=#{variable_name}, link_id=#{link_id}: #{e.class}: #{e.message}"
      skipped_count += 1
    end
  end

  puts "Done. Created #{created_count} rules. Skipped #{skipped_count} rows."
end

# Helpers
def normalize_nilish(value)
  return nil if value.nil?

  str = value.to_s.strip
  return nil if str.empty?
  return nil if ['null', 'NULL', '<null>', '<NULL>'].include?(str)

  str
end

def parse_numeric(value)
  return nil if value.nil?

  str = value.to_s.strip
  return nil if str.empty?

  # Try integer then float
  if str.match?(/\A-?\d+\z/)
    Integer(str)
  else
    Float(str)
  end
rescue ArgumentError
  nil
end

def determine_criteria(definition_row)
  match_value_raw = definition_row['match_value']
  include_raw = definition_row['include']
  gt_raw = definition_row['gt']
  gte_raw = definition_row['gte']
  lt_raw = definition_row['lt']
  lte_raw = definition_row['lte']

  match_value = normalize_nilish(match_value_raw)
  include_value = normalize_nilish(include_raw)

  unless match_value_raw.nil?
    # Raw value present (even if normalized to nil) counts as exact_match
    return ['exact_match', { 'match_value' => match_value }]
  end

  return ['include', { 'include' => include_value }] if include_value

  range_config = {}
  { 'gt' => gt_raw, 'gte' => gte_raw, 'lt' => lt_raw, 'lte' => lte_raw }.each do |key, raw|
    num = parse_numeric(raw)
    range_config[key] = num unless num.nil?
  end

  return ['range', range_config] unless range_config.empty?

  # Fallback to value type with empty config
  ['value', {}]
end
