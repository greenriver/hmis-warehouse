###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudUtility2024
  include ::Concerns::HudValidationUtil
  include ::Concerns::HudLists2024

  module_function

  def races(multi_racial: false)
    return race_field_name_to_description unless multi_racial

    { **race_field_name_to_description, 'MultiRacial' => 'Multi-Racial' }
  end

  def race(field, reverse = false, multi_racial: false)
    map = races(multi_racial: multi_racial)
    _translate map, field, reverse
  end

  # HUD race columns have state-codes in all uppercase, and do not 'camelize' correctly
  def race_column_name(snakecase)
    snakecase.
      camelize.
      gsub('Ak', 'AK').
      gsub('HiPac', 'HIPac'). # Don't substitute 'Hi' in 'Hispanic'
      to_sym
  end

  def ethnicities
    {
      hispanic_latinaeo: 'Hispanic/Latina/e/o',
      non_hispanic_latinaeo: 'Non-Hispanic/Latina/e/o',
      unknown: 'Unknown (Missing, Prefers not to answer, Unknown)',
    }.freeze
  end

  def ethnicity(field, reverse = false)
    map = ethnicities

    _translate map, field, reverse
  end

  def race_ethnicity_combinations
    {
      am_ind_ak_native: 'American Indian, Alaska Native, or Indigenous (only)',
      am_ind_ak_native_hispanic_latinaeo: 'American Indian, Alaska Native, or Indigenous & Hispanic/Latina/e/o',
      asian: 'Asian or Asian American (only)',
      asian_hispanic_latinaeo: 'Asian or Asian American & Hispanic/Latina/e/o',
      black_af_american: 'Black, African American, or African (only)',
      black_af_american_hispanic_latinaeo: 'Black, African American, or African & Hispanic/Latina/e/o',
      hispanic_latinaeo: 'Hispanic/Latina/e/o (only)',
      mid_east_n_african: 'Middle Eastern or North African (only)',
      mid_east_n_african_hispanic_latinaeo: 'Middle Eastern or North African & Hispanic/Latina/e/o',
      native_hi_pacific: 'Native Hawaiian or Pacific Islander (only)',
      native_hi_pacific_hispanic_latinaeo: 'Native Hawaiian or Pacific Islander & Hispanic/Latina/e/o',
      white: 'White (only)',
      white_hispanic_latinaeo: 'White & Hispanic/Latina/e/o',
      multi_racial: 'Multi-racial (all other)',
      multi_racial_hispanic_latinaeo: 'Multi-racial & Hispanic/Latina/e/o',
      race_none: 'Unknown (Missing, Prefers not to answer, Unknown)',
    }.freeze
  end

  def race_ethnicity_combination(field, reverse = false)
    map = race_ethnicity_combinations

    _translate map, field, reverse
  end

  # 1.6
  def gender_none(id, reverse = false)
    race_none(id, reverse)
  end

  def race_gender_none_options
    race_nones
  end

  def veteran_status(*args)
    no_yes_reasons_for_missing_data(*args)
  end

  def project_type_number(type)
    # attempt to lookup full name
    number = project_type(type, true) # reversed
    return number if number.present?

    # perform an acronym lookup
    project_type_brief(type, true) # reversed
  end

  def residential_project_type_numbers_by_code
    {
      ph: [3, 9, 10, 13],
      rrh: [13],
      psh: [3],
      oph: [9, 10],
      th: [2],
      es: [0, 1],
      es_nbn: [1],
      es_entry_exit: [0],
      so: [4],
      sh: [8],
    }.freeze
  end

  def performance_reporting
    { # duplicate of code in various places
      ph: [3, 9, 10, 13],
      rrh: [13],
      psh: [3],
      oph: [9, 10],
      th: [2],
      es: [0, 1],
      es_nbn: [1],
      es_entry_exit: [0],
      so: [4],
      sh: [8],
      ce: [14],
      other: [7],
      day_shelter: [11],
      prevention: [12],
      services_only: [6],
    }.freeze
  end

  def project_type_group_titles
    {
      ph: 'Permanent Housing (PH, PSH, & RRH)',
      es: 'Emergency Shelter (ES NBN & ES Entry/Exit)',
      es_nbn: 'Emergency Shelter (ES NBN)',
      es_entry_exit: 'Emergency Shelter (ES Entry/Exit)',
      th: 'Transitional Housing (TH)',
      sh: 'Safe Haven (SH)',
      so: 'Street Outreach (SO)',
      rrh: 'Rapid Re-Housing (RRH)',
      ce: 'Coordinated Entry (CE)',
      psh: 'Permanent Supportive Housing (PSH)',
      oph: 'Permanent Housing Only (OPH)',
      other: 'Other',
      day_shelter: 'Day Shelter',
      prevention: 'Homelessness Prevention',
      services_only: 'Services Only',
    }.freeze
  end

  def project_types_without_inventory
    [4, 6, 7, 11, 12, 14].freeze
  end

  def homeless_project_type_numbers
    residential_project_type_numbers_by_code.
      values_at(*homeless_project_type_codes).
      flatten.
      uniq.
      sort.
      freeze
  end

  def project_type_number_from_code(code)
    residential_project_type_numbers_by_code[code.to_sym]
  end

  def residential_project_type_numbers_by_codes(*codes)
    codes = codes.flatten # Take either array, or multiple parameters
    codes.map { |code| HudUtility2024.residential_project_type_numbers_by_code[code] }.
      flatten.
      uniq.
      sort.
      freeze
  end

  def homeless_project_type_codes
    [:es, :so, :sh, :th].freeze
  end

  def spm_project_type_codes
    [:es, :so, :sh, :th, :ph].freeze
  end

  def spm_project_type_numbers
    residential_project_type_numbers_by_code.values_at(*spm_project_type_codes).flatten.freeze
  end

  def path_project_type_codes
    [:so, :services_only].freeze
  end

  def residential_project_type_ids
    residential_project_type_numbers_by_codes(residential_project_type_numbers_by_code.keys)
  end

  def chronic_project_types
    literally_homeless_project_types
  end

  def literally_homeless_project_types
    residential_project_type_numbers_by_code.
      values_at(:es, :so, :sh).
      flatten.
      uniq.
      sort.
      freeze
  end

  def homeless_project_types
    residential_project_type_numbers_by_code.
      values_at(:es, :so, :sh, :th).
      flatten.
      uniq.
      sort.
      freeze
  end

  def homeless_sheltered_project_types
    residential_project_type_numbers_by_code.
      values_at(:es, :sh, :th).
      flatten.
      uniq.
      sort.
      freeze
  end

  def homeless_unsheltered_project_types
    residential_project_type_numbers_by_code.
      values_at(:so).
      flatten.
      uniq.
      sort.
      freeze
  end

  def project_type_titles
    project_type_group_titles.
      select { |k, _| k.in?([:ph, :es, :th, :sh, :so]) }.
      freeze
  end

  def homeless_type_titles
    project_type_titles.except(:ph)
  end

  def chronic_type_titles
    project_type_titles.except(:ph)
  end

  def residential_type_titles
    project_type_group_titles.
      select { |k, _| k.in?([:ph, :es, :th, :sh, :so, :rrh, :psh, :oph]) }.
      freeze
  end

  def all_project_types
    project_types.keys
  end

  def project_types_with_inventory
    all_project_types - project_types_without_inventory
  end

  def project_types_with_move_in_dates
    residential_project_type_numbers_by_code[:ph]
  end

  def permanent_housing_project_types
    [
      3, # PH – Permanent Supportive Housing
      9, # PH – Housing Only
      10, # PH – Housing with Services (no disability required for entry)
      13, # PH – Rapid Re-Housing
    ].freeze
  end

  # Projects collecting 4.13 Date of Engagement
  def doe_project_types
    [
      1, # Emergency Shelter – Night-by-Night
      4, # Street Outreach
      6, # Services Only
    ].freeze
  end

  def gender_fields
    gender_id_to_field_name.values.uniq.freeze
  end

  def gender_field_name_to_id
    gender_id_to_field_name.invert.freeze
  end

  def gender_field_name_label
    genders.transform_keys do |k|
      gender_id_to_field_name[k]
    end
  end

  def gender_id_to_field_name
    # Integer values from HUD Data Dictionary
    {
      0 => :Woman,
      1 => :Man,
      2 => :CulturallySpecific,
      3 => :DifferentIdentity,
      4 => :NonBinary,
      5 => :Transgender,
      6 => :Questioning,
      8 => :GenderNone,
      9 => :GenderNone,
      99 => :GenderNone,
    }.freeze
  end

  def gender_known_ids
    [0, 1, 2, 3, 4, 5, 6].freeze
  end

  def gender_known_values
    genders.values_at(*gender_known_ids).freeze
  end

  def gender_comparison_value(key)
    return key if key.in?([8, 9, 99])

    1
  end

  def race_fields
    race_id_to_field_name.values.uniq.freeze
  end

  def race_field_name_to_id
    race_id_to_field_name.invert.freeze
  end

  def race_id_to_field_name
    # Integer values from HUD Data Dictionary
    {
      1 => :AmIndAKNative,
      2 => :Asian,
      3 => :BlackAfAmerican,
      4 => :NativeHIPacific,
      5 => :White,
      6 => :HispanicLatinaeo,
      7 => :MidEastNAfrican,
      8 => :RaceNone,
      9 => :RaceNone,
      99 => :RaceNone,
    }.freeze
  end

  def race_known_ids
    [1, 2, 3, 4, 5, 6, 7].freeze
  end

  def race_known_values
    races.values_at(*race_known_ids).freeze
  end

  def residence_prior_length_of_stay_brief(id, reverse = false)
    map = residence_prior_length_of_stays_brief

    _translate map, id, reverse
  end

  def residence_prior_length_of_stays_brief
    {
      10 => '0-7',
      11 => '0-7',
      2 => '7-30',
      3 => '30-90',
      4 => '90-365',
      5 => '365+',
      8 => '',
      9 => '',
      99 => '',
    }
  end

  def times_homeless_past_three_years_brief(id, reverse = false)
    map = {
      1 => '1',
      2 => '2',
      3 => '3',
      4 => '4+',
      8 => '',
      9 => '',
      99 => '',
    }

    _translate map, id, reverse
  end

  def months_homeless_past_three_years_brief(id, reverse = false)
    map = {
      8 => '',
      9 => '',
      99 => '',
      101 => '0-1',
      102 => '2',
      103 => '3',
      104 => '4',
      105 => '5',
      106 => '6',
      107 => '7',
      108 => '8',
      109 => '9',
      110 => '10',
      111 => '11',
      112 => '12',
      113 => '> 12',
    }

    _translate map, id, reverse
  end

  def valid_current_living_situations
    current_living_situations.keys
  end

  def valid_prior_living_situations
    prior_living_situations.keys
  end

  def valid_destinations
    destinations
  end

  def destination_no_exit_interview_completed
    30
  end

  # See https://www.hudexchange.info/programs/hmis/hmis-data-standards/standards/HMIS-Data-Standards.htm#Appendix_A_-_Living_Situation_Option_List for details
  # Includes ALL situations (prior/current/destination)
  def available_situations
    current_living_situations.merge(destinations).merge(prior_living_situations)
  end

  # In keeping with HudUtility 2022, this is a lookup for ALL situations (current/prior/destination)
  def living_situation(id, reverse = false)
    map = available_situations
    _translate map, id, reverse
  end

  # In keeping with HudUtility 2022, this is a map of ALL situations (current/prior/destination)
  def living_situations
    available_situations
  end

  SITUATION_OTHER_RANGE = (1..99)
  SITUATION_HOMELESS_RANGE = (100..199)
  SITUATION_INSTITUTIONAL_RANGE = (200..299)
  SITUATION_TEMPORARY_RANGE = (300..399)
  SITUATION_PERMANENT_RANGE = (400..499)

  private def situations_for(as)
    case as
    when :prior
      prior_living_situations
    when :current
      current_living_situations
    when :destination
      destinations
    end
  end

  def homeless_situations(as:)
    situations_for(as).keys.filter { |n| SITUATION_HOMELESS_RANGE.include? n }
  end

  def institutional_situations(as:)
    situations_for(as).keys.filter { |n| SITUATION_INSTITUTIONAL_RANGE.include? n }
  end

  def temporary_situations(as:)
    situations_for(as).keys.filter { |n| SITUATION_TEMPORARY_RANGE.include? n }
  end

  def permanent_situations(as:)
    situations_for(as).keys.filter { |n| SITUATION_PERMANENT_RANGE.include? n }
  end

  def temporary_and_permanent_housing_situations(as:)
    temporary_situations(as: as) + permanent_situations(as: as)
  end

  def other_situations(as:)
    situations_for(as).keys.filter { |n| (1..99).include? n }
  end

  def situation_type(id)
    return 'Homeless' if SITUATION_HOMELESS_RANGE.include? id
    return 'Institutional' if SITUATION_INSTITUTIONAL_RANGE.include? id
    return 'Temporary Housing' if SITUATION_TEMPORARY_RANGE.include? id
    return 'Permanent Housing' if SITUATION_PERMANENT_RANGE.include? id
    return 'Other' if SITUATION_OTHER_RANGE.include? id

    'Other'
  end

  def destination_type(id)
    situation_type(id).gsub('Housing', '').strip
  end

  def permanent_destinations
    permanent_situations(as: :destination)
  end

  def temporary_destinations
    temporary_situations(as: :destination)
  end

  def institutional_destinations
    institutional_situations(as: :destination)
  end

  def other_destinations
    other_situations(as: :destination)
  end

  def homeless_destinations
    homeless_situations(as: :destination)
  end

  def homeless_situation_options(as:)
    available_situations.select { |id, _| id.in?(homeless_situations(as: as)) }
  end

  def institutional_situation_options(as:)
    available_situations.select { |id, _| id.in?(institutional_situations(as: as)) }
  end

  def temporary_housing_situation_options(as:)
    available_situations.select { |id, _| id.in?(temporary_situations(as: as)) }
  end

  def permanent_housing_situation_options(as:)
    available_situations.select { |id, _| id.in?(permanent_situations(as: as)) }
  end

  def other_situation_options(as:)
    available_situations.select { |id, _| id.in?(other_situations(as: as)) }
  end

  def temporary_destination_options
    available_situations.select { |id, _| id.in?(temporary_destinations) }
  end

  def permanent_destination_options
    available_situations.select { |id, _| id.in?(permanent_destinations) }
  end

  def coc_name(coc_code)
    cocs.try(:[], coc_code) || coc_code
  end

  def valid_coc?(coc_code)
    cocs.key?(coc_code)
  end

  def cocs_with_codes
    cocs.map do |code, name|
      [
        code,
        "#{name} (#{code})",
      ]
    end.to_h.freeze
  end

  def cocs
    codes = coc_codes_options
    return codes.freeze if Rails.env.production?

    codes.merge(
      {
        'XX-500' => 'Test CoC',
        'XX-501' => '2nd Test CoC',
        'XX-502' => '3rd Test CoC', # testkit
        'XX-518' => '4th Test CoC', # testkit
      },
    ).freeze
  end

  def cocs_in_state(states)
    states = Array.wrap(states).reject(&:blank?).map(&:upcase)
    return cocs if states.empty?

    cocs.select { |code, _| code.first(2).upcase.in?(states) }
  end

  # tranform up hud list for use as an enum
  # {1 => 'Test (this)'} => {'test_this' => 1}
  # @param name [Symbol] method on HudLists
  def hud_list_map_as_enumerable(name)
    original = send(name)
    keyed = original.invert.transform_keys do |key|
      key.downcase.gsub(/[^a-z0-9]+/, ' ').strip.gsub(' ', '_')
    end
    raise "cannot key #{name}" if keyed.size != original.size

    keyed
  end

  def path_funders
    [21]
  end

  # SPM definition of CoC funded projects
  def spm_coc_funders
    [2, 3, 4, 5, 43, 44, 54, 55]
  end

  # "Funder components" that are referenced by the 2024 HUD Data Dictionary.
  # These are used by assessment Form Definition to specify funder applicability rules.
  def funder_components
    {
      'HUD: CoC' => [1, 2, 3, 4, 5, 6, 7, 43, 44, 49], # Includes YHDP
      'HUD: ESG' => [8, 9, 10, 11, 47], # Excludes ESG RUSH
      'HUD: ESG RUSH' => [53], # Even though it has the same "HUD ESG" prefix, HUD Data Dictionary treats it as a separate component
      'HUD: HOPWA' => [13, 14, 15, 16, 17, 18, 19, 48],
      'HHS: PATH' => path_funders,
      'HHS: RHY' => [22, 23, 24, 25, 26],
      'VA: GPD' => [37, 38, 39, 40, 41, 42, 45],
      'VA: SSVF' => [33],
      'VA: Community Contract Safe Haven' => [30],
      'VA: CRS Contract Residential Services' => [27],
      'HUD: Unsheltered Special NOFO' => [54],
      'HUD: Rural Special NOFO' => [55],
      'HUD: HUD-VASH' => [20],
      'HUD: PFS' => [HudUtility2024.funding_source('HUD: Pay for Success', true, raise_on_missing: true)], # Pay for Success
    }
  end

  def funder_component(funder)
    funder_components.find { |_, funders| funders.include?(funder) }&.first
  end

  # field name => ID from Data Dictionary
  def aftercare_method_fields
    {
      email_social_media: 1,
      telephone: 2,
      in_person_individual: 3,
      in_person_group: 4,
    }
  end

  # field name => ID from Data Dictionary
  def counseling_method_fields
    {
      individual_counseling: 1,
      family_counseling: 2,
      group_counseling: 3,
    }
  end

  def ce_events_referrals_to_housing
    [
      12,
      13,
      14,
      15,
      17,
      18,
    ]
  end

  def service_types_provided_map
    {
      141 => {
        list: ::HudUtility2024.path_services_options,
        label_method: :path_services,
      },
      142 => {
        list: ::HudUtility2024.rhy_services_options,
        label_method: :rhy_services,
      },
      143 => {
        list: ::HudUtility2024.hopwa_services_options,
        label_method: :hopwa_services,
      },
      144 => {
        list: ::HudUtility2024.ssvf_services_options,
        label_method: :ssvf_services,
      },
      151 => {
        list: ::HudUtility2024.hopwa_financial_assistance_options,
        label_method: :hopwa_financial_assistance,
      },
      152 => {
        list: ::HudUtility2024.ssvf_financial_assistance_options,
        label_method: :ssvf_financial_assistance,
      },
      161 => {
        list: ::HudUtility2024.path_referral_options,
        label_method: :path_referral,
      },
      200 => {
        list: ::HudUtility2024.bed_night_options,
        label_method: :bed_night,
      },
      210 => {
        list: ::HudUtility2024.voucher_tracking_options,
        label_method: :voucher_tracking,
      },
      300 => {
        list: ::HudUtility2024.moving_on_assistance_options,
        label_method: :moving_on_assistance,
      },
    }.freeze
  end

  def service_type_provided(record_type, type_provided)
    label_method = service_types_provided_map.dig(record_type, :label_method)
    return type_provided unless label_method.present?

    send(label_method, type_provided)
  end

  def service_sub_types_provided_map
    {
      3 => {
        list: ::HudUtility2024.ssvf_sub_type3s,
        label_method: :ssvf_sub_type3,
      },
      4 => {
        list: ::HudUtility2024.ssvf_sub_type4s,
        label_method: :ssvf_sub_type4,
      },
      5 => {
        list: ::HudUtility2024.ssvf_sub_type5s,
        label_method: :ssvf_sub_type5,
      },
    }
  end

  def service_sub_type_provided(record_type, type_provided, sub_type_provided)
    return nil unless record_type == 144 && type_provided.in?(service_sub_types_provided_map.keys)

    label_method = service_sub_types_provided_map.dig(type_provided, :label_method)
    return sub_type_provided unless label_method.present?

    send(label_method, sub_type_provided)
  end

  def assessment_name_by_data_collection_stage
    {
      1 => 'Intake Assessment',
      2 => 'Update Assessment',
      3 => 'Exit Assessment',
      5 => 'Annual Assessment',
      6 => 'Post-Exit Assessment',
    }.freeze
  end
end
