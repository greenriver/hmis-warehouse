###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudUtility2026
  # these modules define class methods (essentially extend)
  include ::Concerns::HudValidationUtil
  include ::Concerns::HudLists2026

  SSN_RGX = /(\w{3})[^\w]?(\w{2})[^\w]?(\w{4})/
  class << self
    # funding_sources => deprecated funding sources
    # funding_sources_current => actual funding sources from HudLists2026
    alias_method :funding_sources_current, :funding_sources
    def funding_source_current(id, reverse = false, raise_on_missing: false)
      _translate(funding_sources_current, id, reverse, raise_on_missing: raise_on_missing)
    end

    alias_method :ssvf_financial_assistance_options_current, :ssvf_financial_assistance_options
    def ssvf_financial_assistance(id, reverse = false, raise_on_missing: false)
      _translate(ssvf_financial_assistance_options_current, id, reverse, raise_on_missing: raise_on_missing)
    end
  end

  ##
  # WARNING: all methods below are class-methods due this this line
  ##
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

  ######
  # START 2024 Deprecated fields
  ######
  def gender_none(id, reverse = false)
    race_none(id, reverse)
  end

  def race_gender_none_options
    race_nones
  end
  ######
  # END 2024 Deprecated fields
  ######

  def veteran_status(*args)
    no_yes_reasons_for_missing_data(*args)
  end

  def rrh_sub_type_sso_only
    1
  end

  def project_type_with_sub_type(type, sub_type = nil)
    [
      project_type(type),
      rrh_sub_type(sub_type),
    ].compact_blank.join(' — ')
  end

  def brief_project_type_with_sub_type(type, sub_type = nil)
    [
      project_type_brief(type),
      rrh_sub_type_brief(sub_type),
    ].compact_blank.join(' — ')
  end

  def rrh_sub_types_brief
    {
      1 => 'SSO',
      2 => 'Housing',
    }.freeze
  end

  def rrh_sub_type_brief(id, reverse = false, raise_on_missing: false)
    _translate(rrh_sub_types_brief, id, reverse, raise_on_missing: raise_on_missing)
  end

  def project_type_number(type)
    # attempt to lookup full name
    number = project_type(type, true) # reversed
    return number if number.present? && number.is_a?(Integer)

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

  # Project Type keys used in HMIS GraphQL API and CE Match expressions
  def hmis_project_type_keys
    {
      0 => 'ES_ENTRY_EXIT',
      1 => 'ES_NBN',
      2 => 'TH',
      3 => 'PH_PSH',
      4 => 'SO',
      6 => 'SSO',
      7 => 'OTHER',
      8 => 'SH',
      9 => 'PH_PH',
      10 => 'PH_OPH',
      11 => 'DAY_SHELTER',
      12 => 'HP',
      13 => 'PH_RRH',
      14 => 'CE',
    }
  end

  def hmis_project_type_key(field, reverse = false)
    field = field.to_s.upcase if reverse
    map = hmis_project_type_keys
    _translate(map, field, reverse, raise_on_missing: true)
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
    codes.map { |code| HudUtility2026.residential_project_type_numbers_by_code[code] }.
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

  # Funders that require Move-in Date collection
  def move_in_date_funders
    [45]
  end

  # Funders that require collecting R20 Aftercare Plans, which is the only data element collected Post-Exit
  def post_exit_aftercare_plans_funders
    [
      22, # HHS: RHY - Basic Center Program (prevention and shelter)
      23, # HHS: RHY - Maternity Group Home for Pregnant and Parenting Youth
      24, # HHS: RHY - Transitional Living Program
      26, # HHS: RHY - Demonstration Project
    ]
  end

  def ce_events_by_code
    {
      es: 10,
      th: 11,
      th_rrh: 12,
      rrh: 13,
      psh: 14,
      oph: 15,
    }.freeze
  end

  def project_to_ce_event_type(project) # Logic is from Data Dictionary 4.20.2 Coordinated Entry Event
    project_type = project.project_type

    es_types = residential_project_type_numbers_by_code[:es] + residential_project_type_numbers_by_code[:sh]
    return ce_events_by_code[:es] if es_types.include?(project_type)

    th_rrh_types = residential_project_type_numbers_by_code[:th] + residential_project_type_numbers_by_code[:rrh]
    if th_rrh_types.include?(project_type)
      # If the project has specific open funders, record this as a joint TH/RRH event. (12)
      return ce_events_by_code[:th_rrh] if project.funders.open_on_date.where(funder: ce_event_joint_th_rrh_funders).any?

      # Otherwise, record the event corresponding to the project type (11 or 13)
      return ce_events_by_code[:th] if residential_project_type_numbers_by_code[:th].include?(project_type)
      return ce_events_by_code[:rrh] if residential_project_type_numbers_by_code[:rrh].include?(project_type)
    end

    psh_types = residential_project_type_numbers_by_code[:psh]
    return ce_events_by_code[:psh] if psh_types.include?(project_type)

    oph_types = residential_project_type_numbers_by_code[:oph]
    ce_events_by_code[:oph] if oph_types.include?(project_type)
  end

  ######
  # START 2024 Deprecated fields
  ######

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

  ######
  # END2024 Deprecated fields
  ######

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

  def situation_other_range = self::SITUATION_OTHER_RANGE
  def situation_homeless_range = self::SITUATION_HOMELESS_RANGE
  def situation_institutional_range = self::SITUATION_INSTITUTIONAL_RANGE
  def situation_temporary_range = self::SITUATION_TEMPORARY_RANGE
  def situation_permanent_range = self::SITUATION_PERMANENT_RANGE

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

    test_codes = {
      'XX-500' => 'Test CoC',
      'XX-501' => '2nd Test CoC',
      'XX-502' => '3rd Test CoC', # testkit
      'XX-518' => '4th Test CoC', # testkit
    }
    # Some legacy test CoCs
    if Rails.env.test?
      test_codes['AA-000'] = 'Test CoC AA-000'
      test_codes['ZZ-000'] = 'Test CoC ZZ-000'
      test_codes['ZZ-100'] = 'Test CoC ZZ-100'
      test_codes['ZZ-999'] = 'Test CoC ZZ-999'
      (0..100).to_a.each do |n|
        test_codes["XX-#{n.to_s.rjust(3, '0')}"] = "Test CoC XX-#{n.to_s.rjust(3, '0')}"
      end
    end
    invalid_codes = ENV['INVALID_COC_CODES'].to_s.split(',')
    test_codes.delete_if { |k, _| invalid_codes&.include?(k) }

    codes.merge(test_codes).freeze
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

  def local_or_other_funding_source
    46
  end

  # SPM definition of CoC funded projects
  def spm_coc_funders
    [2, 3, 4, 5, 6, 43, 44, 54, 55, 56]
  end

  def ce_event_joint_th_rrh_funders
    [45, 54, 55]
  end

  # "Funder components" that are referenced by the 2024 HUD Data Dictionary.
  # These are used by assessment Form Definition to specify funder applicability rules.
  def funder_components
    {
      'HUD: CoC' => [1, 2, 3, 4, 5, 6, 7, 43, 44, 49, 56], # Includes YHDP
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
      'HUD: PFS' => [HudHelper.util('2026').funding_source('HUD: Pay for Success', true, raise_on_missing: true)], # Pay for Success
      'HUD: HOME' => [50, 51],
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

  # field name => ID from Data Dictionary
  def ce_participation_services_fields
    {
      prevention_assessment: 1,
      crisis_assessment: 2,
      housing_assessment: 3,
      direct_services: 4,
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
        list: ::HudHelper.util('2026').path_services_options,
        label_method: :path_services,
      },
      142 => {
        list: ::HudHelper.util('2026').rhy_services_options,
        label_method: :rhy_services,
      },
      143 => {
        list: ::HudHelper.util('2026').hopwa_services_options,
        label_method: :hopwa_services,
      },
      144 => {
        list: ::HudHelper.util('2026').ssvf_services_options,
        label_method: :ssvf_services,
      },
      151 => {
        list: ::HudHelper.util('2026').hopwa_financial_assistance_options,
        label_method: :hopwa_financial_assistance,
      },
      152 => {
        list: ::HudHelper.util('2026').ssvf_financial_assistance_options,
        label_method: :ssvf_financial_assistance,
      },
      161 => {
        list: ::HudHelper.util('2026').path_referral_options,
        label_method: :path_referral,
      },
      200 => {
        list: ::HudHelper.util('2026').bed_night_options,
        label_method: :bed_night,
      },
      210 => {
        list: ::HudHelper.util('2026').voucher_tracking_options,
        label_method: :voucher_tracking,
      },
      300 => {
        list: ::HudHelper.util('2026').moving_on_assistance_options,
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
        list: ::HudHelper.util('2026').ssvf_sub_type3s,
        label_method: :ssvf_sub_type3,
      },
      4 => {
        list: ::HudHelper.util('2026').ssvf_sub_type4s,
        label_method: :ssvf_sub_type4,
      },
      5 => {
        list: ::HudHelper.util('2026').ssvf_sub_type5s,
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

  # Utility for defining age range logic in one place.
  # These can overlap, not all are used in every form dropdown/filter
  def age_range
    {
      'Under 5' => 0..4,
      '5-12' => 5..12,
      '13-17' => 13..17,
      'Under 18' => 0..18,
      '18-24' => 18..24,
      '25-34' => 25..34,
      '35-44' => 35..44,
      '45-54' => 45..54,
      '55-61' => 55..61,
      '55-64' => 55..64,
      '62+' => 62..Float::INFINITY,
      '65+' => 65..Float::INFINITY,
    }
  end

  # Returns funder and project_type pairs that require Current Living Situation (CLS) collection.
  # Based on the FY2026 HUD HMIS Data Dictionary requirements for data element 3.917.1 (Current Living Situation).
  #
  # Interpretation notes (where we deviate from or clarify the data dictionary):
  # - CoC SSO: Funder "HUD: CoC - Supportive Services Only" (4) per the CoC program manual can be set up as
  #   Services Only, Street Outreach, or Coordinated Entry. We err on the side of collecting more data and
  #   require CLS collection for all project types funded by CoC SSO.
  # - YHDP: The data dictionary requires collection for any project type serving clients who meet Category 2 or 3
  #   of the homeless definition. We err on the side of collecting more data and require CLS collection for
  #   all YHDP programs.
  # - Funder-only rules: When a funder is only used for one project type, we do not explicitly add the project
  #   type to the rule. For example, HUD ESG has a specific funder for Street Outreach; we do not add project
  #   type to that rule. The requirement is ultimately driven by the funder, and we err on the side of
  #   collecting CLS for that funder even if the project type is misconfigured.
  def current_living_situation_funder_applicability_requirements
    # helper map for relevant project types
    pt = {
      es_nbn: 1,             # Emergency Shelter - Night-by-Night
      street_outreach: 4,    # Street Outreach
      coordinated_entry: 14, # Coordinated Entry
    }

    # helper map for relevant funder codes
    cls_funder_codes = {
      coc_sso: funding_source('HUD: CoC - Supportive Services Only', true, raise_on_missing: true),
      coc_yhdp: funding_source('HUD: CoC - Youth Homeless Demonstration Program (YHDP)', true, raise_on_missing: true),
      esg_emergency_shelter: funding_source('HUD: ESG - Emergency Shelter (operating and/or essential services)', true, raise_on_missing: true),
      esg_street_outreach: funding_source('HUD: ESG - Street Outreach', true, raise_on_missing: true),
      esg_rush: funding_source('HUD: ESG - RUSH', true, raise_on_missing: true),
      unsheltered_nofo: funding_source('HUD: Unsheltered Special NOFO', true, raise_on_missing: true),
      rural_nofo: funding_source('HUD: Rural Special NOFO', true, raise_on_missing: true),
      path: funding_source('HHS: PATH - Street Outreach & Supportive Services Only', true, raise_on_missing: true),
      rhy_street_outreach: funding_source('HHS: RHY - Street Outreach Project', true, raise_on_missing: true),
    }

    [
      # HUD: CoC – Collection required for SSO - Street Outreach, SSO - Coordinated Entry
      { funder: cls_funder_codes[:coc_sso] },
      # HUD: CoC – Youth Homeless Demonstration Program (YHDP) – Collection required for any project type serving clients who meet Category 2 or 3 of the homeless definition
      { funder: cls_funder_codes[:coc_yhdp] },
      # HUD: ESG – Collection only required for Street Outreach, and NbN shelter
      { funder: cls_funder_codes[:esg_street_outreach] },
      { funder: cls_funder_codes[:esg_emergency_shelter], project_type: pt[:es_nbn] },
      # HUD: ESG RUSH – Collection required for Street Outreach, Coordinated Entry, and ES - NbN
      { funder: cls_funder_codes[:esg_rush], project_type: pt[:street_outreach] },
      { funder: cls_funder_codes[:esg_rush], project_type: pt[:coordinated_entry] },
      { funder: cls_funder_codes[:esg_rush], project_type: pt[:es_nbn] },
      # HUD: Unsheltered Special NOFO – Collection required for SSO – Street Outreach, SSO – Coordinated Entry
      { funder: cls_funder_codes[:unsheltered_nofo], project_type: pt[:street_outreach] },
      { funder: cls_funder_codes[:unsheltered_nofo], project_type: pt[:coordinated_entry] },
      # HUD: Rural Special NOFO – Collection required for SSO – Street Outreach, SSO – Coordinated Entry
      { funder: cls_funder_codes[:rural_nofo], project_type: pt[:street_outreach] },
      { funder: cls_funder_codes[:rural_nofo], project_type: pt[:coordinated_entry] },
      # HHS: PATH – Collection required for all components
      { funder: cls_funder_codes[:path] },
      # HHS: RHY – Collection only required for Street Outreach
      { funder: cls_funder_codes[:rhy_street_outreach] },
    ]
  end

  # Returns the configuration that drives which HUD Service form system rules are created.
  # Used by HudComplianceFormInstanceMaintainer to ensure HUD compliance for HMIS application.
  # Based on the FY2026 HUD HMIS Data Dictionary. For each service type, refer to the
  # "Funder: Program-Component" section in the Data Dictionary to verify which funders and
  # project types require collection.
  #
  # Each element has :record_type (HUD record type code) and :applicability_requirements, an array of
  # hashes with :project_type and/or :funder (same shape as current_living_situation_funder_applicability_requirements).
  def service_form_funder_applicability_requirements
    # helper map for relevant project types
    pt = {
      es_nbn: 1, # Emergency Shelter - Night-by-Night
      psh: 3,    # PH - Permanent Supportive Housing
    }

    # helper map for relevant funder codes (named entries used in applicability_requirements below)
    service_funder_codes = {
      path: funding_source('HHS: PATH - Street Outreach & Supportive Services Only', true, raise_on_missing: true),
      hud_vash: funding_source('HUD: HUD/VASH', true, raise_on_missing: true),
      coc_psh: funding_source('HUD: CoC - Permanent Supportive Housing', true, raise_on_missing: true),
      yhdp: funding_source('HUD: CoC - Youth Homeless Demonstration Program (YHDP)', true, raise_on_missing: true),
      rhy_street_outreach: funding_source('HHS: RHY - Street Outreach Project', true, raise_on_missing: true),
      coc_builds: funding_source('HUD: CoC Builds', true, raise_on_missing: true),
      unsheltered_nofo: funding_source('HUD: Unsheltered Special NOFO', true, raise_on_missing: true),
      rural_nofo: funding_source('HUD: Rural Special NOFO', true, raise_on_missing: true),
      ssvf: funding_source('VA: Supportive Services for Veteran Families', true, raise_on_missing: true),
    }
    rhy_funders_excluding_street_outreach = funding_sources.select { |_, v| v.start_with?('HHS: RHY') }.keys - [service_funder_codes[:rhy_street_outreach]]
    hopwa_funders = funder_components.fetch('HUD: HOPWA')

    [
      # 4.14 Bed-Night Date
      {
        record_type: record_type('Bed Night', true, raise_on_missing: true),
        data_collected_about: :ALL_CLIENTS,
        applicability_requirements: [
          # Required for ES NbN ("Applicability extends to all NbN type emergency shelters that participate in HMIS, regardless of funding source")
          { project_type: pt[:es_nbn] },
        ],
      },
      # P1 Services Provided - PATH Funded
      {
        record_type: record_type('PATH Service', true, raise_on_missing: true),
        data_collected_about: :HOH_AND_ADULTS,
        applicability_requirements: [
          # Funder Program-Component: "HHS: PATH – Collection required for all components"
          { funder: service_funder_codes[:path] },
        ],
      },

      # P2 Referrals Provided - PATH
      {
        record_type: record_type('PATH Referral', true, raise_on_missing: true),
        data_collected_about: :HOH_AND_ADULTS,
        applicability_requirements: [
          # Funder Program-Component: "HHS: PATH – Collection required for all components"
          { funder: service_funder_codes[:path] },
        ],
      },

      # R14 RHY Service Connections
      {
        record_type: record_type('RHY Service Connections', true, raise_on_missing: true),
        data_collected_about: :HOH_AND_ADULTS,
        # Funder Program-Component: "HHS: RHY – Collection required for components – as outlined above"
        #
        # Notes:
        # - RHY Street Outreach Project funder (25) is excluded because dictionary indicates it does not collect these services
        # - YHDP funder (43) is excluded because YHDP Program Manual indicates that R14 is optional
        # - All RHY Service Connections sub-types are made available to the applicable funders, even though the
        #   HUD spec indicates particular subsets based on RHY funder. For example, "Home-based Services" type is
        #   only required for RHY BCP (Funder 22) projects.
        applicability_requirements: rhy_funders_excluding_street_outreach.map { |funder| { funder: funder } },
      },

      # W1 Services Provided – HOPWA
      {
        record_type: record_type('HOPWA Service', true, raise_on_missing: true),
        data_collected_about: :ALL_CLIENTS,
        # Funder Program-Component: "HUD: HOPWA – Collection required for all components"
        applicability_requirements: hopwa_funders.map { |funder| { funder: funder } },
      },

      # W2 Financial Assistance – HOPWA
      {
        record_type: record_type('HOPWA Financial Assistance', true, raise_on_missing: true),
        data_collected_about: :HOH,
        # Funder Program-Component: "HUD: HOPWA – Collection required for PHP and STRMU only as indicated above"
        #
        # Notes:
        # - We enable this record type for all HOPWA-funded projects, despite HUD only requiring collection for PHP and STRMU.
        #   If a future customer wants these service types hidden from other HOPWA-funded projects (e.g. 'Housing Information' funder 14),
        #   then we could make this more narrow to accommodate them.
        applicability_requirements: hopwa_funders.map { |funder| { funder: funder } },
      },

      # V2 Services Provided – SSVF
      {
        record_type: record_type('SSVF Service', true, raise_on_missing: true),
        data_collected_about: :ALL_CLIENTS,
        # Funder Program-Component: "VA: SSVF – Collection required for RRH and Homelessness Prevention"
        #
        # Notes:
        # - We enable this record type for all SSVF-funded projects, despite HUD only requiring collection for RRH and Homelessness Prevention.
        # - Other VA-funded programs may optionally collect this, we don't include them here because collection is not required.
        applicability_requirements: [{ funder: service_funder_codes[:ssvf] }],
      },

      # V3 Financial Assistance – SSVF
      {
        record_type: record_type('SSVF Financial Assistance', true, raise_on_missing: true),
        data_collected_about: :ALL_CLIENTS,
        applicability_requirements: [
          # Funder Program-Component: "VA: SSVF – Collection required for RRH and Homelessness Prevention"
          #
          # Notes:
          # - We enable this record type for all SSVF-funded projects, despite HUD only requiring collection for RRH and Homelessness Prevention.
          # - Other VA-funded programs may optionally collect this, we don't include them here because collection is not required.
          { funder: service_funder_codes[:ssvf] },
        ],
      },
      # V8 HUD-VASH Voucher Tracking
      #
      # Note: Dictionary requires collection for 'Head of Household/Veteran', we make the service type available
      # for all adults in the household to err on the side of enabling more data collection.
      {
        record_type: record_type('HUD-VASH OTH Voucher Tracking', true, raise_on_missing: true),
        data_collected_about: :HOH_AND_ADULTS,
        applicability_requirements: [
          # Funder Program-Component: "HUD: HUD-VASH – Collection required for HUD/VASH Collaborative Case Management"
          { project_type: pt[:psh], funder: service_funder_codes[:hud_vash] },
        ],
      },

      # C2 Moving On Assistance Provided
      {
        record_type: record_type('Moving On Assistance', true, raise_on_missing: true),
        data_collected_about: :HOH,
        applicability_requirements: [
          #   HUD: CoC – Collection required for Permanent Supportive Housing
          { project_type: pt[:psh], funder: service_funder_codes[:coc_psh] },
          #   HUD: CoC – Youth Homeless Demonstration Program (YHDP) – Collection required for Permanent Supportive Housing
          { project_type: pt[:psh], funder: service_funder_codes[:coc_yhdp] },
          #   HUD: CoC Builds – Collection required for Permanent Supportive Housing
          { project_type: pt[:psh], funder: service_funder_codes[:coc_builds] },
          #   HUD: Unsheltered Special NOFO – Collection required for Permanent Supportive Housing
          { project_type: pt[:psh], funder: service_funder_codes[:unsheltered_nofo] },
          #   HUD: Rural Special NOFO – Collection required for Permanent Supportive Housing
          { project_type: pt[:psh], funder: service_funder_codes[:rural_nofo] },
        ],
      },
    ]
  end
end
