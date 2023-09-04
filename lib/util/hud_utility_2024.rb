###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

  def homeless_project_type_numbers
    [
      0, # ES E/E
      1, # ES NBN
      2, # TH
      4, # SO
      8, # SH
    ].freeze
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

  private def funder_description_to_component(description)
    return unless description.include?(' - ')

    description.split(' - ')[0]
  end
  def funder_components
    funding_sources.
      transform_values { |d| funder_description_to_component(d) }.
      compact.
      each_with_object({}) { |(k, v), h| (h[v] ||= []) << k }
  end

  def funder_component(funder)
    funding_sources.
      transform_values { |d| funder_description_to_component(d) }.
      compact[funder]
  end

  def path_funders
    [21]
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
end
