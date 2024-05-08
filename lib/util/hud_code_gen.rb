###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
module HudCodeGen
  CODEGEN_FILE_HEADER = '# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY'.freeze

  MAP_NAME_OVERRIDES = {
    export_period_types: :period_types,
    no_yes_missings: :yes_no_missing_options,
    no_yes_reasons_for_missing_data: :no_yes_reasons_for_missing_data_options,
    name_data_qualities: :name_data_quality_options,
    ssn_data_qualities: :ssn_data_quality_options,
    dob_data_qualities: :dob_data_quality_options,
    residence_prior_length_of_stays: :length_of_stays,
    times_homeless_past_three_years: :times_homeless_options,
    months_homeless_past_three_years: :month_categories,
    relationship_to_ho_hs: :relationships_to_hoh,
    when_dv_occurreds: :when_occurreds,
    event_types: :events,
    dependent_under6s: :dependent_under_6,
    hopwa_financial_assistances: :hopwa_financial_assistance_options,
    ssvf_financial_assistances: :ssvf_financial_assistance_options,
    path_referrals: :path_referral_options,
    rhy_referrals: :rhy_referral_options,
    bed_nights: :bed_night_options,
    voucher_trackings: :voucher_tracking_options,
    moving_on_assistances: :moving_on_assistance_options,
    races: :race_field_name_to_description,
  }.stringify_keys.freeze

  LOOKUP_FN_OVERRIDES = {
    relationship_to_ho_h: :relationship_to_hoh,
    when_dv_occurred: :when_d_v_occurred,
    event_type: :event,
    dependent_under6: :dependent_under_6,
  }.stringify_keys.freeze

  GRAPHQL_NAME_OVERRIDES = {
    # Necessary for enums where name overlaps with an existing GQL type
    CurrentLivingSituation: :CurrentLivingSituationOptions,
  }.stringify_keys.freeze

  module_function

  def generate_hud_lists(year = '2024')
    source = File.read("lib/data/#{year}_hud_lists.json")
    all_lists = JSON.parse(source).sort_by { |hash| hash['code'] }
    skipped = []
    filename = "lib/util/concerns/hud_lists_#{year}.rb"
    arr = []
    arr.push ::Code.copywright_header
    arr.push "
      # frozen_string_literal: true
      #{CODEGEN_FILE_HEADER}
      module Concerns::HudLists#{year}
        extend ActiveSupport::Concern
          class_methods do
    "

    all_lists.each do |element|
      next if skipped.include?(element['code'].to_s)

      map_values = element['values'].map do |obj|
        description = obj['description'].strip
        "#{obj['key'].to_json} => \"#{description}\""
      end.join(",\n")

      map_name, lookup_fn_name = get_function_names(element['name'])

      arr.push "
      # #{element['code']}
      def #{map_name}
        {\n#{map_values}\n}.freeze
      end

      def #{lookup_fn_name}(id, reverse = false)
        _translate #{map_name}, id, reverse
      end
      "
    end
    arr.push 'end'
    arr.push 'end'
    contents = arr.join("\n")
    File.open(filename, 'w') do |f|
      f.write(contents)
    end
    filename
  end

  def generate_graphql_enums(year = '2024')
    source = File.read("lib/data/#{year}_hud_lists.json")
    skipped = ['race', '3.6.1', '2.4.2', '1.6']
    filename = 'drivers/hmis/app/graphql/types/hmis_schema/enums/hud.rb'
    hud_utility_class = year == '2022' ? 'HudUtility' : "HudUtility#{year}"

    seen = []
    arr = []
    arr.push ::Code.copywright_header
    arr.push "
      # frozen_string_literal: true

      module Types::HmisSchema::Enums::Hud
    "
    JSON.parse(source).each do |element|
      next if skipped.include?(element['code'].to_s)

      name = element['name']
      next if seen.include?(name)

      map_name = get_function_names(name)[0]
      graphql_name = GRAPHQL_NAME_OVERRIDES[name] || name
      arr.push "class #{name} < Types::BaseEnum"
      enum_description = "HUD #{name}"
      enum_description << " (#{element['code']})" if element['code']
      arr.push "description '#{enum_description}'"
      arr.push "graphql_name '#{graphql_name}'"
      # graphql name; description; value
      enum_map = hud_utility_class.constantize.send(map_name)

      stringify_values = enum_map.keys.any? { |k| k.is_a?(String) }
      enum_map.each do |key, value|
        enum_key = Types::BaseEnum.to_enum_key(value)
        enum_key = 'DATA_NOT_COLLECTED' if key.to_s == '99'

        enum_description = "(#{key}) #{value}"
        enum_value = key
        escaped_value = stringify_values ? "'#{enum_value}'" : enum_value
        arr.push "value '#{enum_key}', \"#{enum_description}\", value: #{escaped_value}"
      end
      arr.push "value 'INVALID', 'Invalid Value', value: #{Types::BaseEnum::INVALID_VALUE}"
      arr.push 'end'
      seen << name
    end

    arr.push 'end'
    contents = arr.join("\n")
    File.open(filename, 'w') do |f|
      f.write(contents)
    end
    filename
  end

  private def get_function_names(name)
    lookup_fn_name = name.underscore
    map_name = lookup_fn_name.pluralize

    # apply overrides
    map_name = MAP_NAME_OVERRIDES[map_name] if MAP_NAME_OVERRIDES.key?(map_name)
    lookup_fn_name = LOOKUP_FN_OVERRIDES[lookup_fn_name] if LOOKUP_FN_OVERRIDES.key?(lookup_fn_name)

    # funcs cannot have the same name
    map_name = "#{map_name}_options" if map_name == lookup_fn_name

    [map_name, lookup_fn_name]
  end

  def generate_hud_list_json(year, excel_file_path)
    # Parse the existing JSON data. This will be the base from which we start.
    json_file_path = "lib/data/#{year}_hud_lists.json"
    json_data = JSON.parse(File.read(json_file_path))

    # Some codes are irrelevant to this transformation, we'll ignore them based on string comparison
    ignore_codes = ['List', '*', '(see note)']
    excel_file = Roo::Excelx.new(excel_file_path)

    # Parse Excel file for list codes
    excel_data = {}.tap do |codes|
      # Sheet 0: CSV|DE#|Name|Type|List|Null|Notes|Validate
      # Pull from this sheet to get the names for each list of codes

      # Verify headers in the sheet being processed match what is expected
      raise 'Unexpected Sheet Headers' unless excel_file.sheet(0).row(1).eql?(['CSV', 'DE#', 'Name', 'Type', 'List', 'Null', 'Notes', 'Validate'])

      excel_file.sheet(0).each(code: 'List', name: 'Name') do |row|
        # Clean data coming in from excel
        code = clean_json_text(row[:code].to_s)
        list_name = clean_json_text(row[:name].to_s)

        # Only need rows that have referenced codes - not all data on this sheet utilizes a code list
        next if code.blank? || ignore_codes.include?(code)

        codes[code] ||= { list_name: [] }
        codes[code][:list_name] ||= []
        codes[code][:list_name] << list_name
      end
      # Sheet 1: List|Value|Text
      # This sheet does not have names for the lists, but it may include some that are not referenced in
      # the first sheet. In this case, bring the code list in with a name "Unknown". These ones will need
      # to be manually checked and named.

      # Verify headers in the sheet being processed match what is expected
      raise 'Unexpected Sheet Headers' unless excel_file.sheet(1).row(1).eql?(['List', 'Value', 'Text'])

      excel_file.sheet(1).each(code: 'List', value: 'Value', text: 'Text') do |row|
        # Clean data coming in from excel
        code = clean_json_text(row[:code].to_s)
        value = clean_json_text(row[:value].to_s)
        text = clean_json_text(row[:text].to_s)
        value = value.to_i if Integer(value, exception: false)

        # Skip header and blank rows if they exist
        next if code.blank? || ignore_codes.include?(code)

        codes[code] ||= { list_name: ['Unknown'], values: {} }
        codes[code][:values] ||= {}
        codes[code][:values][value] = text
      end
    end

    # Sort the values - they may be coming in with a string sort (e.g. 1, 10, 11, 2, 3 ...)
    excel_data.each do |node|
      node.last[:values] = node.last[:values].sort_by { |k, _v| k.to_i }
    end

    # We now have the codes in the json file and the excel file. We need to merge them together.
    # This will be done by scanning the JSON file for codes that don't exist in the Excel file
    # and removing them. Then scanning the Excel file for codes that don't exist in the JSON
    # file and adding them.

    # List of just the codes in the JSON data
    json_codes = json_data.collect { |e| e['code'] }

    # Update values for known codes
    (json_codes & excel_data.keys).each do |e|
      json_node = json_data.detect { |n| n['code'].eql?(e) }
      excel_node = excel_data[e]
      json_node['values'] = []
      excel_node[:values].each do |v|
        json_node['values'] << { 'key': v.first, 'description': v.last }
      end
    end

    # Remove all json nodes with codes not matching an excel code
    json_data_clean = json_data.reject { |e| (json_codes - excel_data.keys).include?(e['code']) }

    # Add new from excel that don't exist in the JSON
    (excel_data.keys - json_codes).each do |e|
      excel_node = excel_data[e]
      code_name = excel_node[:list_name].first
      code_name = 'Unknown' if excel_node[:list_name].count != 1
      json = {
        'name' => code_name,
        'code' => e,
      }
      excel_node[:values].each do |v|
        (json[:values] ||= []) << { 'key': v.first, 'description': v.last }
      end
      json_data_clean.push(json)
    end

    # Pull in Additional JSON Data
    Dir.glob("lib/data/#{year}_additional_lists/*.json") do |json_file|
      data = JSON.parse(File.read(json_file))
      json_data_clean.push(data.first)
    end

    # Sort the nodes
    numeric, not_numeric = json_data_clean.partition { |node| node['code'].start_with?(/[0-9]/) } # Separate out codes beginning with numeric and those beginning with alpha
    numeric.sort_by! { |x| x['code'].scan(/\d+|\D+/).map(&:to_i) } # Sort by numeric portions of each code
    not_numeric.sort_by { |x| [x['code'].split('.').map(&:ord), x['code']] } # Sort by numeric portions of each code
    json_data_clean = numeric + not_numeric # Rejoin with alpha codes at the end

    # Output to file
    File.write(json_file_path, JSON.pretty_generate(json_data_clean))
  end

  private def clean_json_text(str)
    str = str.strip.delete("\u00A0").
      gsub(/\u2019/, "'"). # replace the character U+2019 "’" could be confused with the ASCII character U+0027 "'",
      gsub(/\u2013/, '-')  # replace the character U+2013 "–" with the ASCII character U+002d "-"
    str
  end
end
