###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
  }.stringify_keys.freeze

  LOOKUP_FN_OVERRIDES = {
    relationship_to_ho_h: :relationship_to_hoh,
    when_dv_occurred: :when_d_v_occurred,
    event_type: :event,
    dependent_under6: :dependent_under_6,
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
      #{CODEGEN_FILE_HEADER}
      module Types::HmisSchema::Enums::Hud
    "
    JSON.parse(source).each do |element|
      next if skipped.include?(element['code'].to_s)

      name = element['name']
      next if seen.include?(name)

      map_name = get_function_names(name)[0]

      arr.push "  class #{name} < Types::BaseEnum"
      arr.push "    description '#{element['code'] || name}'"
      arr.push "    graphql_name '#{name}'"
      arr.push "    hud_enum #{hud_utility_class}.#{map_name}"
      arr.push '  end'
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
end
