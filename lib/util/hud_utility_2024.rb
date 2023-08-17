###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudUtility2024
  include ::Concerns::HudValidationUtil
  include ::Concerns::HudLists2024

  module_function

  # def race(field, reverse = false, multi_racial: false)
  #   map = races(multi_racial: multi_racial)
  #   _translate map, field, reverse
  # end

  # # NOTE: HUD, in the APR specifies these by order ID, as noted in the comments below
  # def races(multi_racial: false)
  #   race_list = {
  #     'AmIndAKNative' => 'American Indian, Alaska Native, or Indigenous', # 1
  #     'Asian' => 'Asian or Asian American', # 2
  #     'BlackAfAmerican' => 'Black, African American, or African', # 3
  #     'NativeHIPacific' => 'Native Hawaiian or Pacific Islander', # 4
  #     'White' => 'White', # 5
  #     'RaceNone' => 'Doesn\'t Know, refused, or not collected', # 6 (can be 99, 8, 9, null only if all other race fields are 99 or 0)
  #   }
  #   race_list['MultiRacial'] = 'Multi-Racial' if multi_racial
  #   race_list
  # end

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

  def project_group_titles
    {
      ph: 'Permanent Housing (PH, PSH, & RRH)',
      es: 'Emergency Shelter (ES)',
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

  def homeless_project_type_codes
    [:es, :so, :sh, :th].freeze
  end

  def spm_project_type_codes
    [:es, :so, :sh, :th, :ph].freeze
  end

  def path_project_type_codes
    [:so, :services_only].freeze
  end

  def residential_project_type_ids
    residential_project_type_numbers_by_code.
      values.
      flatten.
      uniq.
      sort.
      freeze
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
    project_group_titles.
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
    project_group_titles.
      select { |k, _| k.in?([:ph, :es, :th, :sh, :so, :rrh, :psh, :oph]) }.
      freeze
  end

  def all_project_types
    project_types.keys
  end

  def project_types_with_inventory
    all_project_types - project_types_without_inventory
  end

  def with_move_in_dates
    residential_project_type_numbers_by_code[:ph]
  end

  def gender_fields
    gender_id_to_field_name.values.uniq.freeze
  end

  def gender_field_name_to_id
    gender_id_to_field_name.invert.freeze
  end

  def gender_id_to_field_name
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

  def gender_comparison_value(key)
    return key if key.in?([8, 9, 99])

    1
  end

  # TODO(2024) update for APR/CAPER/CE APR
  def no_single_gender_queries
    HudUtility.no_single_gender_queries
  end

  # TODO(2024) update for APR/CAPER/CE APR
  def questioning_gender_queries
    HudUtility.questioning_gender_queries
  end

  # TODO(2024) update for APR/CAPER/CE APR
  def transgender_gender_queries
    HudUtility.transgender_gender_queries
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
    situation_type(id)
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
    HudUtility.cocs_with_codes
  end

  def cocs
    HudUtility.cocs
  end

  def cocs_in_state(state)
    HudUtility.cocs_in_state(state)
  end

  # This value indicates that the field is null if the column is non-nullable
  def ignored_enum_value
    999
  end

  # tranform up hud list for use as an enum
  # {1 => 'Test (this)'} => {'test_this' => 1}
  # @param name [Symbol] method on HudLists
  def hud_list_map_as_enumerable(name)
    HudUtility.hud_list_map_as_enumerable(name)
  end
end
