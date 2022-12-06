# a general clearing house to translate HUD ids of various sorts into strings
# further access or translation logic can also go here
# information from HMIS CSV format specifications version 5
module HUD
  module_function

  # factored out of app/models/grda_warehouse/tasks/identify_duplicates.rb
  def valid_social?(ssn)
    # see https://en.wikipedia.org/wiki/Social_Security_number#Structure
    return false if ssn.blank? || ssn.length != 9

    area_number = ssn.first(3)
    group_number = ssn[3..4]
    serial_number = ssn.last(4)

    # Fields can't be all zeros
    return false if area_number.to_i.zero? || group_number.to_i.zero? || serial_number.to_i.zero?
    # Fields must be numbers
    return false unless digits?(area_number) && digits?(group_number) && digits?(serial_number)
    # 900+ are not assigned, and 666 is excluded
    return false if area_number.to_i >= 900 || area_number == '666'
    # Published IDs are not valid
    return false if ['219099999', '078051120', '123456789'].include?(ssn)
    return false if ssn.split('').uniq.count == 1 # all the same number

    true
  end

  private def digits?(value)
    value.match(/^\d+$/).present?
  end

  def fiscal_year_start
    Date.new(fiscal_year - 1, 10, 1)
  end

  def fiscal_year_end
    Date.new(fiscal_year, 9, 30)
  end

  def fiscal_year
    return Date.current.year if Date.current.month >= 10

    Date.current.year - 1
  end

  def describe_valid_social_rules
    [
      'Cannot contain a non-numeric character.',
      'Must be 9 digits long.',
      'First three digits cannot be "000," "666," or in the 900 series.',
      'The second group / 5th and 6th digits cannot be "00".',
      'The third group / last four digits cannot be "0000".',
      'There cannot be repetitive (e.g. "333333333") or sequential (e.g. "345678901" "987654321")',
      'numbers for all 9 digits.',
    ]
  end

  def describe_valid_dob_rules
    [
      'Prior to 1/1/1915.',
      'After the [Date Created] for the record.',
      'Equal to or after the [Entry Date].',
    ]
  end

  # for fuzzy translation from strings back to their controlled vocabulary key
  def forgiving_regex(str)
    return str if str.is_a?(Integer)

    Regexp.new '^' + str.strip.gsub(/\W+/, '\W+') + '$', 'i'
  end

  def _translate(map, id, reverse)
    if reverse
      rx = forgiving_regex id
      if rx.is_a?(Regexp)
        map.detect { |_, v| v.match?(rx) }.try(&:first)
      else
        map.detect { |_, v| v == rx }.try(&:first)
      end
    else
      map[id] || id
    end
  end

  def race(field, reverse = false, multi_racial: false)
    map = races(multi_racial: multi_racial)
    _translate map, field, reverse
  end

  # NOTE: HUD, in the APR specifies these by order ID, as noted in the comments below
  def races(multi_racial: false)
    race_list = {
      'AmIndAKNative' => 'American Indian, Alaska Native, or Indigenous', # 1
      'Asian' => 'Asian or Asian American', # 2
      'BlackAfAmerican' => 'Black, African American, or African', # 3
      'NativeHIPacific' => 'Native Hawaiian or Pacific Islander', # 4
      'White' => 'White', # 5
      'RaceNone' => 'Doesn\'t Know, refused, or not collected', # 6 (can be 99, 8, 9, null only if all other race fields are 99 or 0)
    }
    race_list['MultiRacial'] = 'Multi-Racial' if multi_racial
    race_list
  end

  # for translating straight from a controlled vocabulary list identifier and integer
  # to the corresponding phrase
  def list(number, id, reverse = false)
    method = ::HudLists.hud_code_to_function_map[number.to_s.to_sym]
    raise "unknown controlled vocabulary list: #{number}" unless method

    map = ::HudLists.send(method)
    _translate(map, id, reverse)
  end

  # 1.1
  def export_period_type(id, reverse = false)
    map = period_types

    _translate map, id, reverse
  end

  def period_types
    ::HudLists.export_period_type_map
  end

  # 1.2
  def export_directive(id, reverse = false)
    map = export_directives

    _translate map, id, reverse
  end

  def export_directives
    ::HudLists.export_directive_map
  end

  # 1.3
  def disability_type(id, reverse = false)
    map = disability_types
    _translate map, id, reverse
  end

  def disability_types
    ::HudLists.disability_type_map
  end

  # 1.4
  def record_type(id, reverse = false)
    map = record_types

    _translate map, id, reverse
  end

  def record_types
    ::HudLists.record_type_map
  end

  # 1.5
  def hash_status(id, reverse = false)
    map = hash_statuses

    _translate map, id, reverse
  end

  def hash_statuses
    ::HudLists.hash_status_map
  end

  # 1.6
  def gender_none(id, reverse = false)
    race_none(id, reverse)
  end

  def race_none(id, reverse = false)
    map = race_gender_none_options

    _translate map, id, reverse
  end

  def race_gender_none_options
    ::HudLists.race_none_map
  end

  # 1.7
  def no_yes_missing(id, reverse = false)
    map = yes_no_missing_options

    _translate map, id, reverse
  end

  def yes_no_missing_options
    ::HudLists.no_yes_missing_map
  end

  # FIXME: Remove this?
  def ad_hoc_yes_no_1(id, reverse = false)
    map = {
      0 => 'No',
      1 => 'Yes',
      8 => "Don't Know",
      9 => 'Refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 1.8
  def no_yes_reasons_for_missing_data(id, reverse = false)
    map = no_yes_reasons_for_missing_data_options

    _translate map, id, reverse
  end

  def no_yes_reasons_for_missing_data_options
    ::HudLists.no_yes_reasons_for_missing_data_map
  end

  def veteran_status(*args)
    no_yes_reasons_for_missing_data(*args)
  end

  # 1.9
  def source_type(id, reverse = false)
    map = source_types

    _translate map, id, reverse
  end

  def source_types
    ::HudLists.source_type_map
  end

  # 2.02.6
  def project_type(id, reverse = false, translate = true)
    map = project_types
    if translate
      _translate map, id, reverse
    else
      map
    end
  end

  def project_types
    ::HudLists.project_type_map
  end

  def project_type_brief(id)
    case id
    when 1
      'ES'
    when 2
      'TH'
    when 3
      'PH'
    when 4
      'SO'
    when 6
      'Services Only'
    when 7
      'Other'
    when 8
      'SH'
    when 9
      'PH'
    when 10
      'PH'
    when 11
      'Day Shelter'
    when 12
      'Homeless Prevention'
    when 13
      'PH-RRH'
    when 14
      'CE'
    end
  end

  # 2.02.C
  def tracking_method(id, reverse = false)
    map = tracking_methods

    _translate map, id, reverse
  end

  def tracking_methods
    # FIXME Do we want the nil mapping?
    ::HudLists.tracking_method_map.merge(nil => 'Entry/Exit Date')
  end

  # 2.06.1
  def funding_sources
    ::HudLists.funding_source_map
  end

  def funding_source(id, reverse = false)
    map = funding_sources
    _translate map, id, reverse
  end

  # 2.07.4
  def household_type(id, reverse = false)
    map = household_types

    _translate map, id, reverse
  end

  def household_types
    ::HudLists.household_type_map
  end

  # 2.07.5
  def bed_type(id, reverse = false)
    map = bed_types

    _translate map, id, reverse
  end

  def bed_types
    ::HudLists.bed_type_map
  end

  # 2.07.6
  def availability(id, reverse = false)
    map = availabilities

    _translate map, id, reverse
  end

  def availabilities
    ::HudLists.availability_map
  end

  # 2.7.B
  def youth_age_group(id, reverse = false)
    map = youth_age_groups

    _translate map, id, reverse
  end

  def youth_age_groups
    ::HudLists.youth_age_group_map
  end

  # 2.03.4
  def geography_type(id, reverse = false)
    map = geography_types

    _translate map, id, reverse
  end

  def geography_types
    ::HudLists.geography_type_map
  end

  # 2.02.D
  def housing_type(id, reverse = false)
    map = housing_types

    _translate map, id, reverse
  end

  def housing_types
    ::HudLists.housing_type_map
  end

  # 2.02.8
  def target_population(id, reverse = false)
    map = target_populations

    _translate map, id, reverse
  end

  def target_populations
    ::HudLists.target_population_map
  end

  # 2.02.9
  def h_o_p_w_a_med_assisted_living_fac(id, reverse = false)
    map = h_o_p_w_a_med_assisted_living_facs

    _translate map, id, reverse
  end

  def h_o_p_w_a_med_assisted_living_facs
    ::HudLists.hopwa_med_assisted_living_fac_map
  end

  # 3.01.5
  def name_data_quality(id, reverse = false)
    _translate(name_data_quality_options, id, reverse)
  end

  def name_data_quality_options
    ::HudLists.name_data_quality_map
  end

  # 3.02.2
  def ssn_data_quality(id, reverse = false)
    _translate(ssn_data_quality_options, id, reverse)
  end

  def ssn_data_quality_options
    ::HudLists.ssn_data_quality_map
  end

  # 3.03.2
  def dob_data_quality(id, reverse = false)
    map = dob_data_quality_options

    _translate map, id, reverse
  end

  def dob_data_quality_options
    ::HudLists.dob_data_quality_map
  end

  # 3.05.1
  def ethnicity(id, reverse = false)
    map = ethnicities

    _translate map, id, reverse
  end

  def ethnicities
    ::HudLists.ethnicity_map
  end

  # 3.06.1
  def gender(id, reverse = false)
    map = genders
    _translate map, id, reverse
  end

  def genders
    ::HudLists.gender_map
  end

  def gender_fields
    gender_id_to_field_name.values.uniq.freeze
  end

  def gender_field_name_to_id
    gender_id_to_field_name.invert.freeze
  end

  def gender_id_to_field_name
    {
      0 => :Female,
      1 => :Male,
      4 => :NoSingleGender,
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

  def no_single_gender_queries
    [
      '0,1',
      '0,1,4',
      '0,1,4,5',
      '0,1,5',
      '0,4',
      '0,4,5',
      '1,4',
      '1,4,5',
      '4',
      '4,5',
    ]
  end

  def questioning_gender_queries
    [
      '0,1,4,5,6',
      '0,1,4,6',
      '0,1,5,6',
      '0,1,6',
      '0,4,5,6',
      '0,4,6',
      '0,5,6',
      '0,6',
      '1,4,5,6',
      '1,4,6',
      '1,5,6',
      '1,6',
      '4,5,6',
      '4,6',
      '5,6',
      '6',
    ]
  end

  def transgender_gender_queries
    [
      '0,5',
      '1,5',
      '5',
    ]
  end

  # 3.917.1
  def living_situation(id, reverse = false)
    map = living_situations
    _translate map, id, reverse
  end

  def living_situations
    # Technically this should exclude 13, 12, 22, 23, 26, 27, 30, 17, 24, 37
    ::HudLists.living_situation_map
  end

  # 3.917.2
  def residence_prior_length_of_stay(id, reverse = false)
    map = length_of_stays

    _translate map, id, reverse
  end

  def length_of_stays
    ::HudLists.residence_prior_length_of_stay_map
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

  # 3.917.4
  def times_homeless_past_three_years(id, reverse = false)
    map = times_homeless_options

    _translate map, id, reverse
  end

  def times_homeless_options
    ::HudLists.times_homeless_past_three_years_map
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

  # 3.917.5
  def months_homeless_past_three_years(id, reverse = false)
    map = month_categories

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
      113 => '12+', # FIXME should this be 13+?
    }

    _translate map, id, reverse
  end

  def month_categories
    ::HudLists.months_homeless_past_three_years_map
  end

  # 3.12.1
  def destination(id, reverse = false)
    map = valid_destinations

    _translate map, id, reverse
  end

  def valid_destinations
    ::HudLists.destination_map
  end

  def valid_current_living_situations
    homeless_situations(as: :current) +
    institutional_situations(as: :current) +
    temporary_and_permanent_housing_situations(as: :current) +
    other_situations(as: :current)
  end

  def valid_prior_living_situations
    homeless_situations(as: :prior) +
    institutional_situations(as: :prior) +
    temporary_and_permanent_housing_situations(as: :prior) +
    other_situations(as: :prior)
  end

  # See https://www.hudexchange.info/programs/hmis/hmis-data-standards/standards/HMIS-Data-Standards.htm#Appendix_A_-_Living_Situation_Option_List for details
  def available_situations
    ::HudLists.destination_map
    {
      1 => 'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or RHY-funded Host Home shelter ',
      2 => 'Transitional housing for homeless persons (including homeless youth)',
      3 => 'Permanent housing (other than RRH) for formerly homeless persons',
      4 => 'Psychiatric hospital or other psychiatric facility',
      5 => 'Substance abuse treatment facility or detox center',
      6 => 'Hospital or other residential non-psychiatric medical facility',
      7 => 'Jail, prison or juvenile detention facility',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      10 => 'Rental by client, no ongoing housing subsidy',
      11 => 'Owned by client, no ongoing housing subsidy',
      12 => 'Staying or living with family, temporary tenure (e.g. room, apartment or house)',
      13 => 'Staying or living with friends, temporary tenure (e.g. room apartment or house)',
      14 => 'Hotel or motel paid for without emergency shelter voucher',
      15 => 'Foster care home or foster care group home',
      16 => 'Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)',
      17 => 'Other',
      18 => 'Safe Haven',
      19 => 'Rental by client, with VASH housing subsidy',
      20 => 'Rental by client, with other ongoing housing subsidy',
      21 => 'Owned by client, with ongoing housing subsidy',
      22 => 'Staying or living with family, permanent tenure',
      23 => 'Staying or living with friends, permanent tenure',
      24 => 'Deceased',
      25 => 'Long-term care facility or nursing home',
      26 => 'Moved from one HOPWA funded project to HOPWA PH',
      27 => 'Moved from one HOPWA funded project to HOPWA TH',
      28 => 'Rental by client, with GPD TIP housing subsidy',
      29 => 'Residential project or halfway house with no homeless criteria',
      30 => 'No exit interview completed',
      31 => 'Rental by client, with RRH or equivalent subsidy',
      32 => 'Host Home (non-crisis)',
      33 => 'Rental by client, with HCV voucher (tenant or project based)',
      34 => 'Rental by client in a public housing unit',
      35 => 'Staying or living in a family member\'s room, apartment or house',
      36 => 'Staying or living in a friend\'s room, apartment or house',
      37 => 'Worker unable to determine',
      99 => 'Data not collected',
    }
  end

  def homeless_situations(as:, version: nil)
    case version
    when '2020', nil
      case as
      when :prior, :current, :destination
        [
          16,
          1,
          18,
        ]
      end
    end
  end

  def institutional_situations(as:, version: nil)
    case version
    when '2020', '2022', nil
      case as
      when :prior, :current, :destination
        [
          15,
          6,
          7,
          25,
          4,
          5,
        ]
      end
    end
  end

  def temporary_and_permanent_housing_situations(as:, version: nil)
    case version
    when '2020', '2022', nil
      case as
      when :prior, :current
        [
          29,
          14,
          2,
          32,
          36,
          35,
          28,
          19,
          3,
          31,
          33,
          34,
          10,
          20,
          21,
          11,
        ]
      when :destination
        [
          29,
          14,
          2,
          32,
          13,
          12,
          22,
          23,
          26,
          27,
          28,
          19,
          3,
          31,
          33,
          34,
          10,
          20,
          21,
          11,
        ]
      end
    end
  end

  def other_situations(as:, version: nil)
    case version
    when '2020', '2022', nil
      case as
      when :prior
        [
          8,
          9,
          99,
        ]
      when :current
        [
          17,
          37,
          8,
          9,
          99,
        ]
      when :destination
        [
          30,
          17,
          24,
          8,
          9,
          99,
        ]
      end
    end
  end

  def situation_type(id, include_homeless_breakout: false)
    return 'Temporary or Permanent' if temporary_and_permanent_housing_situations(as: :prior).include?(id)
    return 'Institutional' if institutional_situations(as: :prior).include?(id)
    return 'Homeless' if homeless_situations(as: :prior).include?(id) && include_homeless_breakout
    return 'Other' if homeless_situations(as: :prior).include?(id)

    'Other'
  end

  def destination_type(id)
    return 'Permanent' if permanent_destinations.include?(id)
    return 'Temporary' if temporary_destinations.include?(id)
    return 'Institutional' if institutional_destinations.include?(id)
    return 'Homeless' if homeless_destinations.include?(id)

    'Other'
  end

  def permanent_destinations(version: nil)
    case version
    when '2020', nil # From SPM 3.1 definition
      [
        26,
        11,
        21,
        3,
        10,
        28,
        20,
        19,
        22,
        23,
        31,
        33,
        34,
      ].freeze
    end
  end

  def temporary_destinations(version: nil)
    case version
    when '2020', nil
      [
        15,
        14,
        27,
        4,
        12,
        13,
        5,
        2,
        25,
        32,
        29,
      ]
    end
  end

  def institutional_destinations(version: nil)
    institutional_situations(as: :destination, version: version)
  end

  def other_destinations(version: nil)
    other_situations(as: :destination, version: version)
  end

  def homeless_destinations(version: nil)
    homeless_situations(as: :destination, version: version)
  end

  def homeless_situation_options(as:)
    available_situations.select { |id, _| id.in?(homeless_situations(as: as)) }.to_h
  end

  def institutional_situation_options(as:)
    available_situations.select { |id, _| id.in?(institutional_situations(as: as)) }.to_h
  end

  def temporary_and_permanent_housing_situation_options(as:)
    available_situations.select { |id, _| id.in?(temporary_and_permanent_housing_situations(as: as)) }.to_h
  end

  def other_situation_options(as:)
    available_situations.select { |id, _| id.in?(other_situations(as: as)) }.to_h
  end

  def temporary_destination_options(version: nil)
    available_situations.select { |id, _| id.in?(temporary_destinations(version: version)) }.to_h
  end

  def permanent_destination_options(version: nil)
    available_situations.select { |id, _| id.in?(permanent_destinations(version: version)) }.to_h
  end

  # 3.15.1
  def relationship_to_hoh(id, reverse = false)
    map = relationships_to_hoh

    _translate map, id, reverse
  end

  def relationships_to_hoh
    ::HudLists.relationship_to_ho_h_map
  end

  # 4.1.1
  def housing_status(id, reverse = false)
    map = ::HudLists.housing_status_map

    _translate map, id, reverse
  end

  # 4.04.A
  def reason_not_insured(id, reverse = false)
    map = ::HudLists.reason_not_insured_map

    _translate map, id, reverse
  end

  # 4.9.D
  def p_a_t_h_how_confirmed(id, reverse = false)
    map = ::HudLists.path_how_confirmed_map

    _translate map, id, reverse
  end

  # 4.9.E
  def p_a_t_h_s_m_i_information(id, reverse = false)
    map = ::HudLists.pathsmi_information_map

    _translate map, id, reverse
  end

  # 4.10.2
  def disability_response(id, reverse = false)
    map = disability_responses

    _translate map, id, reverse
  end

  def disability_responses
    ::HudLists.disability_response_map
  end

  # 4.11.A
  def when_d_v_occurred(id, reverse = false)
    map = when_occurreds
    _translate map, id, reverse
  end

  def when_occurreds
    ::HudLists.when_dv_occurred_map
  end

  # 4.12.2
  def contact_location(id, reverse = false)
    map = ::HudLists.contact_location_map

    _translate map, id, reverse
  end

  # P1.2
  def p_a_t_h_services_map
    ::HudLists.path_services_map
  end

  def p_a_t_h_services(id, reverse = false)
    map = p_a_t_h_services_map

    _translate map, id, reverse
  end

  # R14.2
  def r_h_y_services_map
    ::HudLists.rhy_services_map
  end

  def r_h_y_services(id, reverse = false)
    map = r_h_y_services_map

    _translate map, id, reverse
  end

  # W1.2
  def h_o_p_w_a_services_map
    ::HudLists.hopwa_services_map
  end

  def h_o_p_w_a_services(id, reverse = false)
    map = h_o_p_w_a_services_map

    _translate map, id, reverse
  end

  # V2.2
  def s_s_v_f_services_map
    ::HudLists.ssvf_services_map
  end

  def s_s_v_f_services(id, reverse = false)
    map = s_s_v_f_services_map

    _translate map, id, reverse
  end

  # V2.A
  def s_s_v_f_sub_type3_map
    ::HudLists.ssvf_sub_type3_map
  end

  def s_s_v_f_sub_type3(id, reverse = false)
    map = s_s_v_f_sub_type3_map

    _translate map, id, reverse
  end

  # V2.B
  def s_s_v_f_sub_type4_map
    ::HudLists.ssvf_sub_type4_map
  end

  def s_s_v_f_sub_type4(id, reverse = false)
    map = s_s_v_f_sub_type4_map

    _translate map, id, reverse
  end

  # V2.C
  def s_s_v_f_sub_type5_map
    ::HudLists.ssvf_sub_type5_map
  end

  def s_s_v_f_sub_type5(id, reverse = false)
    map = s_s_v_f_sub_type5_map

    _translate map, id, reverse
  end

  # W2.3
  def h_o_p_w_a_financial_assistance_map
    ::HudLists.hopwa_financial_assistance_map
  end

  def h_o_p_w_a_financial_assistance(id, reverse = false)
    map = h_o_p_w_a_financial_assistance_map

    _translate map, id, reverse
  end

  # 4.14
  def bed_night_map
    ::HudLists.bed_night_map
  end

  def bed_night(id, reverse = false)
    map = bed_night_map

    _translate map, id, reverse
  end

  # V3.3
  def s_s_v_f_financial_assistance_map
    ::HudLists.ssvf_financial_assistance_map
  end

  def s_s_v_f_financial_assistance(id, reverse = false)
    map = s_s_v_f_financial_assistance_map

    _translate map, id, reverse
  end

  # P2.2
  def p_a_t_h_referral_map
    ::HudLists.path_referral_map
  end

  def p_a_t_h_referral(id, reverse = false)
    map = p_a_t_h_referral_map

    _translate map, id, reverse
  end

  # R14.2
  def r_h_y_referral(id, reverse = false)
    ::HudLists.rhy_referral_map

    _translate map, id, reverse
  end

  # P2.A
  def p_a_t_h_referral_outcome_map
    ::HudLists.path_referral_outcome_map
  end

  def p_a_t_h_referral_outcome(id, reverse = false)
    map = p_a_t_h_referral_outcome_map

    _translate map, id, reverse
  end

  # 4.18.1
  def housing_assessment_disposition(id, reverse = false)
    map = ::HudLists.housing_assessment_disposition_map

    _translate map, id, reverse
  end

  # W5.1
  def housing_assessment_at_exit(id, reverse = false)
    map = ::HudLists.housing_assessment_at_exit_map

    _translate map, id, reverse
  end

  # 4.19.3
  def assessment_type(id, reverse = false)
    map = assessment_types

    _translate map, id, reverse
  end

  def assessment_types
    ::HudLists.assessment_type_map
  end

  # 4.19.4
  def assessment_level(id, reverse = false)
    map = assessment_levels

    _translate map, id, reverse
  end

  def assessment_levels
    ::HudLists.assessment_level_map
  end

  # 4.19.7
  def prioritization_status(id, reverse = false)
    map = prioritization_statuses

    _translate map, id, reverse
  end

  def prioritization_statuses
    ::HudLists.prioritization_status_map
  end

  # W5.A
  def subsidy_information(id, reverse = false)
    map = ::HudLists.subsidy_information_map

    _translate map, id, reverse
  end

  # P3.A
  def reason_not_enrolled(id, reverse = false)
    map = ::HudLists.reason_not_enrolled_map

    _translate map, id, reverse
  end

  # 4.20.2
  def event(id, reverse = false)
    map = events

    _translate map, id, reverse
  end

  def events
    ::HudLists.event_type_map
  end

  # 4.20.D
  def referral_results
    ::HudLists.referral_result_map
  end

  def referral_result(id, reverse = false)
    map = referral_results

    _translate map, id, reverse
  end

  # R2.A
  def reason_no_services(id, reverse = false)
    map = ::HudLists.reason_no_services_map

    _translate map, id, reverse
  end

  # R3.1
  def sexual_orientation(id, reverse = false)
    map = ::HudLists.sexual_orientation_map

    _translate map, id, reverse
  end

  # R4.1
  def last_grade_completed(id, reverse = false)
    map = ::HudLists.last_grade_completed_map

    _translate map, id, reverse
  end

  # R5.1
  def school_status(id, reverse = false)
    map = ::HudLists.school_status_map

    _translate map, id, reverse
  end

  # R6.A
  def employment_type(id, reverse = false)
    map = ::HudLists.employment_type_map

    _translate map, id, reverse
  end

  # R6.B
  def not_employed_reason(id, reverse = false)
    map = ::HudLists.not_employed_reason_map

    _translate map, id, reverse
  end

  # R7.1
  def health_status(id, reverse = false)
    map = ::HudLists.health_status_map

    _translate map, id, reverse
  end

  # R11.A
  def r_h_y_numberof_years(id, reverse = false)
    map = ::HudLists.rhy_numberof_years_map

    _translate map, id, reverse
  end

  # 4.33.A
  def incarcerated_parent_status(id, reverse = false)
    map = ::HudLists.incarcerated_parent_status_map

    _translate map, id, reverse
  end

  # R1.1
  def referral_source(id, reverse = false)
    map = ::HudLists.referral_source_map

    _translate map, id, reverse
  end

  # R15.B
  def count_exchange_for_sex(id, reverse = false)
    map = ::HudLists.count_exchange_for_sex_map

    _translate map, id, reverse
  end

  # 4.36.1
  def exit_action(id, reverse = false)
    map = ::HudLists.exit_action_map

    _translate map, id, reverse
  end

  # R17.1
  def project_completion_status(id, reverse = false)
    map = ::HudLists.project_completion_status_map

    _translate map, id, reverse
  end

  # 4.37.A
  def early_exit_reason(id, reverse = false)
    map = ::HudLists.early_exit_reason_map

    _translate map, id, reverse
  end

  # R17.A
  def expelled_reason(id, reverse = false)
    map = ::HudLists.expelled_reason_map

    _translate map, id, reverse
  end

  # R19.A
  def worker_response(id, reverse = false)
    map = ::HudLists.worker_response_map

    _translate map, id, reverse
  end

  # R20.2
  def aftercare_provided(id, reverse = false)
    map = ::HudLists.aftercare_provided_map

    _translate map, id, reverse
  end

  # W3
  def no_assistance_reason(id, reverse = false)
    map = ::HudLists.no_assistance_reason_map

    _translate map, id, reverse
  end

  # V1.11
  def military_branch(id, reverse = false)
    map = ::HudLists.military_branch_map

    _translate map, id, reverse
  end

  # V1.12
  def discharge_status(id, reverse = false)
    map = ::HudLists.discharge_status_map

    _translate map, id, reverse
  end

  # V4.1
  def percent_a_m_i(id, reverse = false)
    map = ::HudLists.percent_ami_map

    _translate map, id, reverse
  end

  # V5.5
  def address_data_quality(id, reverse = false)
    map = ::HudLists.address_data_quality_map

    _translate map, id, reverse
  end

  # V6.1
  def vamcs_station_number(id, reverse = false)
    map = ::HudLists.vamcs_station_number_map

    _translate map, id, reverse
  end

  # W4.B
  def t_cell_source_viral_load_source(id, reverse = false)
    map = ::HudLists.t_cell_source_viral_load_source_map

    _translate map, id, reverse
  end

  # W4.3
  def viral_load_available(id, reverse = false)
    map = ::HudLists.viral_load_available_map

    _translate map, id, reverse
  end

  # V7.1
  def no_points_yes(id, reverse = false)
    map = ::HudLists.no_points_yes_map

    _translate map, id, reverse
  end

  # V7.A
  def time_to_housing_loss(id, reverse = false)
    map = ::HudLists.time_to_housing_loss_map

    _translate map, id, reverse
  end

  # V7.B
  def annual_percent_a_m_i(id, reverse = false)
    map = ::HudLists.annual_percent_ami_map

    _translate map, id, reverse
  end

  # V7.G
  def eviction_history(id, reverse = false)
    map = ::HudLists.eviction_history_map

    _translate map, id, reverse
  end

  # V7.C
  def literal_homeless_history(id, reverse = false)
    map = ::HudLists.literal_homeless_history_map

    _translate map, id, reverse
  end

  # V7.I
  def incarcerated_adult
    map = ::HudLists.incarcerated_adult_map

    _translate map, id, reverse
  end

  # V7.O
  def dependent_under_6
    map = ::HudLists.dependent_under6_map

    _translate map, id, reverse
  end

  # V8.1
  def voucher_tracking_map
    ::HudLists.voucher_tracking_map
  end

  def voucher_tracking(id, reverse = false)
    map = voucher_tracking_map

    _translate map, id, reverse
  end

  # V9.1
  def cm_exit_reason(id, reverse = false)
    map = ::HudLists.cm_exit_reason_map

    _translate map, id, reverse
  end

  # 4.49.1
  def crisis_services_use(id, reverse = false)
    map = ::HudLists.crisis_services_use_map

    _translate map, id, reverse
  end

  # 5.03.1
  def data_collection_stage(id, reverse = false)
    map = data_collection_stages

    _translate map, id, reverse
  end

  # C1.1
  def wellbeing_agreement(id, reverse = false)
    map = ::HudLists.wellbeing_agreement_map

    _translate map, id, reverse
  end

  # C1.2
  def feeling_frequency(id, reverse = false)
    map = ::HudLists.feeling_frequency_map

    _translate map, id, reverse
  end

  # C2.2
  def moving_on_assistance_map
    ::HudLists.moving_on_assistance_map
  end

  def moving_on_assistance
    map = moving_on_assistance_map
    _translate map, id, reverse
  end

  # C3.2
  def current_school_attended(id, reverse = false)
    map = ::HudLists.current_school_attended_map

    _translate map, id, reverse
  end

  # C3.A
  def most_recent_ed_status(id, reverse = false)
    map = ::HudLists.most_recent_ed_status

    _translate map, id, reverse
  end

  # C3.B
  def current_ed_status(id, reverse = false)
    map = ::HudLists.current_ed_status_map

    _translate map, id, reverse
  end

  def data_collection_stages
    ::HudLists.data_collection_stage_map
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
    codes = {
      'CO-500' => 'Colorado Balance of State CoC',
      'CO-503' => 'Metropolitan Denver CoC',
      'CO-504' => 'Colorado Springs/El Paso County CoC',
      'CT-505' => 'Connecticut Balance of State CoC',
      'FL-501' => 'Tampa/Hillsborough County CoC',
      'FL-504' => 'Daytona Beach, Daytona/Volusia, Flagler Counties CoC',
      'IL-507' => 'Peoria, Pekin/Fulton, Tazewell, Peoria, Woodford Counties CoC',
      'FL-505' => 'Fort Walton Beach/Okaloosa, Walton Counties CoC',
      'FL-507' => 'Orlando/Orange, Osceola, Seminole Counties CoC',
      'FL-509' => 'Fort Pierce/St. Lucie, Indian River, Martin Counties CoC',
      'FL-510' => 'Jacksonville-Duval, Clay Counties CoC',
      'FL-512' => 'St. Johns County CoC',
      'FL-514' => 'Ocala/Marion County CoC',
      'FL-515' => 'Panama City/Bay, Jackson Counties CoC',
      'FL-520' => 'Citrus, Hernando, Lake, Sumter Counties CoC',
      'FL-600' => 'Miami-Dade County CoC',
      'AK-501' => 'Alaska Balance of State CoC',
      'AL-501' => 'Mobile City & County/Baldwin County CoC',
      'AL-503' => 'Huntsville/North Alabama CoC',
      'AL-504' => 'Montgomery City & County CoC',
      'AL-507' => 'Alabama Balance of State CoC',
      'AL-506' => 'Tuscaloosa City & County CoC',
      'AR-500' => 'Little Rock/Central Arkansas CoC',
      'AR-503' => 'Arkansas Balance of State CoC',
      'AR-505' => 'Southeast Arkansas CoC',
      'AR-512' => 'Boone, Baxter, Marion, Newton Counties CoC',
      'AZ-501' => 'Tucson/Pima County CoC',
      'CA-501' => 'San Francisco CoC',
      'CA-502' => 'Oakland, Berkeley/Alameda County CoC',
      'CA-505' => 'Richmond/Contra Costa County CoC',
      'CA-506' => 'Salinas/Monterey, San Benito Counties CoC',
      'CA-508' => 'Watsonville/Santa Cruz City & County CoC',
      'CA-511' => 'Stockton/San Joaquin County CoC',
      'CA-512' => 'Daly City/San Mateo County CoC',
      'CA-514' => 'Fresno City & County/Madera County CoC',
      'CA-516' => 'Redding/Shasta, Siskiyou, Lassen, Plumas, Del Norte, Modoc, Sierra Counties CoC',
      'CA-517' => 'Napa City & County CoC',
      'CA-520' => 'Merced City & County CoC',
      'CA-523' => 'Colusa, Glenn, Trinity Counties CoC',
      'CA-527' => 'Tehama County CoC',
      'CA-530' => 'Alpine, Inyo, Mono Counties CoC',
      'CA-603' => 'Santa Maria/Santa Barbara County CoC',
      'CA-608' => 'Riverside City & County CoC',
      'GA-503' => 'Athens-Clarke County CoC',
      'GA-505' => 'Columbus-Muscogee/Russell County CoC',
      'KS-507' => 'Kansas Balance of State CoC',
      'CA-612' => 'Glendale CoC',
      'CA-613' => 'Imperial County CoC',
      'CA-614' => 'San Luis Obispo County CoC',
      'IA-502' => 'Des Moines/Polk County CoC',
      'FL-603' => 'Ft Myers, Cape Coral/Lee County CoC',
      'MA-504' => 'Springfield/Hampden County CoC',
      'IL-510' => 'Chicago CoC',
      'IL-511' => 'Cook County CoC',
      'IL-512' => 'Bloomington/Central Illinois CoC',
      'IL-514' => 'Dupage County CoC',
      'IL-515' => 'South Central Illinois CoC',
      'IL-516' => 'Decatur/Macon County CoC',
      'IL-500' => 'McHenry County CoC',
      'IL-501' => 'Rockford/Winnebago, Boone Counties CoC',
      'IL-503' => 'Champaign, Urbana, Rantoul/Champaign County CoC',
      'IL-504' => 'Madison County CoC',
      'NV-500' => 'Las Vegas/Clark County CoC',
      'KS-502' => 'Wichita/Sedgwick County CoC',
      'KS-503' => 'Topeka/Shawnee County CoC',
      'KS-505' => 'Overland Park, Shawnee/Johnson County CoC',
      'IL-517' => 'Aurora, Elgin/Kane County CoC',
      'IL-518' => 'Rock Island, Moline/Northwestern Illinois CoC',
      'IL-519' => 'West Central Illinois CoC',
      'IL-520' => 'Southern Illinois CoC',
      'LA-502' => 'Shreveport, Bossier/Northwest Louisiana CoC',
      'HI-501' => 'Honolulu City and County CoC',
      'FL-605' => 'West Palm Beach/Palm Beach County CoC',
      'FL-606' => 'Naples/Collier County CoC',
      'GA-501' => 'Georgia Balance of State CoC',
      'GA-502' => 'Fulton County CoC',
      'GA-504' => 'Augusta-Richmond County CoC',
      'ID-501' => 'Idaho Balance of State CoC',
      'LA-505' => 'Monroe/Northeast Louisiana CoC',
      'MI-509' => 'Washtenaw County CoC',
      'MI-510' => 'Saginaw City & County CoC',
      'MI-511' => 'Lenawee County CoC',
      'MI-512' => 'Grand Traverse, Antrim, Leelanau Counties CoC',
      'MI-513' => 'Marquette, Alger Counties CoC',
      'MI-514' => 'Battle Creek/Calhoun County CoC',
      'MI-517' => 'Jackson City & County CoC',
      'MI-523' => 'Eaton County CoC',
      'KY-502' => 'Lexington-Fayette County CoC',
      'LA-500' => 'Lafayette/Acadiana Regional CoC',
      'LA-509' => 'Louisiana Balance of State CoC',
      'LA-503' => 'New Orleans/Jefferson Parish CoC',
      'LA-506' => 'Slidell/Southeast Louisiana CoC',
      'LA-507' => 'Alexandria/Central Louisiana CoC',
      'LA-508' => 'Houma-Terrebonne, Thibodaux CoC',
      'MA-502' => 'Lynn CoC',
      'GA-506' => 'Marietta/Cobb County CoC',
      'GA-507' => 'Savannah/Chatham County CoC',
      'HI-500' => 'Hawaii Balance of State CoC',
      'ID-500' => 'Boise/Ada County CoC',
      'NC-513' => 'Chapel Hill/Orange County CoC',
      'NE-500' => 'Nebraska Balance of State CoC',
      'NJ-506' => 'Jersey City, Bayonne/Hudson County CoC',
      'NJ-507' => 'New Brunswick/Middlesex County CoC',
      'IA-500' => 'Sioux City/Dakota, Woodbury Counties CoC',
      'NV-502' => 'Nevada Balance of State CoC',
      'NY-501' => 'Elmira/Steuben, Allegany, Livingston, Chemung, Schuyler Counties CoC',
      'NY-602' => 'Newburgh, Middletown/Orange County CoC',
      'MA-510' => 'Gloucester, Haverhill, Salem/Essex County CoC',
      'NY-500' => 'Rochester, Irondequoit, Greece/Monroe County CoC',
      'MA-516' => 'Massachusetts Balance of State CoC',
      'MA-519' => 'Attleboro, Taunton/Bristol County CoC',
      'MA-599' => 'MA-510 & MA-516 Shared Jurisdiction',
      'MI-504' => 'Pontiac, Royal Oak/Oakland County CoC',
      'MI-505' => 'Flint/Genesee County CoC',
      'NJ-513' => 'Somerset County CoC',
      'NJ-514' => 'Trenton/Mercer County CoC',
      'NJ-516' => 'Warren, Sussex, Hunterdon Counties CoC',
      'NM-500' => 'Albuquerque CoC',
      'NM-501' => 'New Mexico Balance of State CoC',
      'OH-500' => 'Cincinnati/Hamilton County CoC',
      'NY-503' => 'Albany City & County CoC',
      'NY-505' => 'Syracuse, Auburn/Onondaga, Oswego, Cayuga Counties CoC',
      'NY-508' => 'Buffalo, Niagara Falls/Erie, Niagara, Orleans, Genesee, Wyoming Counties CoC',
      'MD-501' => 'Baltimore CoC',
      'MD-502' => 'Harford County CoC',
      'MD-504' => 'Howard County CoC',
      'MD-505' => 'Baltimore County CoC',
      'MD-510' => 'Garrett County CoC',
      'MD-513' => 'Wicomico, Somerset, Worcester Counties CoC',
      'MD-601' => 'Montgomery County CoC',
      'MN-500' => 'Minneapolis/Hennepin County CoC',
      'MI-501' => 'Detroit CoC',
      'MN-501' => 'St. Paul/Ramsey County CoC',
      'ND-500' => 'North Dakota Statewide CoC',
      'NY-600' => 'New York City CoC',
      'NY-604' => 'Yonkers, Mount Vernon/Westchester County CoC',
      'NY-607' => 'Sullivan County CoC',
      'OH-507' => 'Ohio Balance of State CoC',
      'NC-507' => 'Raleigh/Wake County CoC',
      'NY-606' => 'Rockland County CoC',
      'NH-500' => 'New Hampshire Balance of State CoC',
      'MN-502' => 'Rochester/Southeast Minnesota CoC',
      'MN-503' => 'Dakota, Anoka, Washington, Scott, Carver Counties CoC',
      'MN-504' => 'Northeast Minnesota CoC',
      'MN-505' => 'St. Cloud/Central Minnesota CoC',
      'MN-508' => 'Moorhead/West Central Minnesota CoC',
      'MO-500' => 'St. Louis County CoC',
      'MO-503' => 'St. Charles City & County, Lincoln, Warren Counties CoC',
      'NC-511' => 'Fayetteville/Cumberland County CoC',
      'NC-516' => 'Northwest North Carolina CoC',
      'NC-502' => 'Durham City & County CoC',
      'NJ-509' => 'Morris County CoC',
      'MO-602' => 'Joplin/Jasper, Newton Counties CoC',
      'MO-604' => 'Kansas City (MO&KS), Independence, Lee\'s Summit/Jackson, Wyandotte Counties CoC',
      'MO-606' => 'Missouri Balance of State CoC',
      'MS-501' => 'Mississippi Balance of State CoC',
      'MS-503' => 'Gulf Port/Gulf Coast Regional CoC',
      'NC-503' => 'North Carolina Balance of State CoC',
      'NC-505' => 'Charlotte/Mecklenburg County CoC',
      'NC-506' => 'Wilmington/Brunswick, New Hanover, Pender Counties CoC',
      'NJ-512' => 'Salem County CoC',
      'NY-504' => 'Cattaraugus County CoC',
      'MA-509' => 'Cambridge CoC',
      'NY-608' => 'Kingston/Ulster County CoC',
      'OH-505' => 'Dayton, Kettering/Montgomery County CoC',
      'OH-506' => 'Akron/Summit County CoC',
      'IN-502' => 'Indiana Balance of State CoC',
      'OH-502' => 'Cleveland/Cuyahoga County CoC',
      'OH-503' => 'Columbus/Franklin County CoC',
      'NH-501' => 'Manchester CoC',
      'PA-502' => 'Upper Darby, Chester, Haverford/Delaware County CoC',
      'PA-503' => 'Wilkes-Barre, Hazleton/Luzerne County CoC',
      'PA-506' => 'Reading/Berks County CoC',
      'PA-500' => 'Philadelphia CoC',
      'PA-509' => 'Eastern Pennsylvania CoC',
      'PA-512' => 'York City & County CoC',
      'NY-510' => 'Ithaca/Tompkins County CoC',
      'NY-511' => 'Binghamton, Union Town/Broome, Otsego, Chenango, Delaware, Cortland, Tioga Counties CoC',
      'NY-513' => 'Wayne, Ontario, Seneca, Yates Counties CoC',
      'NY-516' => 'Clinton County CoC',
      'NY-519' => 'Columbia, Greene Counties CoC',
      'NY-520' => 'Franklin, Essex Counties CoC',
      'NY-523' => 'Glens Falls, Saratoga Springs/Saratoga, Washington, Warren, Hamilton Counties CoC',
      'OK-501' => 'Tulsa City & County CoC',
      'OK-503' => 'Oklahoma Balance of State CoC',
      'PA-508' => 'Scranton/Lackawanna County CoC',
      'TN-502' => 'Knoxville/Knox County CoC',
      'TN-504' => 'Nashville-Davidson County CoC',
      'TN-509' => 'Appalachian Regional CoC',
      'NH-502' => 'Nashua/Hillsborough County CoC',
      'NJ-500' => 'Atlantic City & County CoC',
      'NJ-502' => 'Burlington County CoC',
      'NJ-504' => 'Newark/Essex County CoC',
      'NJ-508' => 'Monmouth County CoC',
      'NJ-511' => 'Paterson/Passaic County CoC',
      'OR-503' => 'Central Oregon CoC',
      'OR-507' => 'Clackamas County CoC',
      'PA-501' => 'Harrisburg/Dauphin County CoC',
      'PA-505' => 'Chester County CoC',
      'OK-502' => 'Oklahoma City CoC',
      'VA-503' => 'Virginia Beach CoC',
      'CA-504' => 'Santa Rosa, Petaluma/Sonoma County CoC',
      'RI-500' => 'Rhode Island Statewide CoC',
      'IA-501' => 'Iowa Balance of State CoC',
      'IL-502' => 'Waukegan, North Chicago/Lake County CoC',
      'WV-500' => 'Wheeling, Weirton Area CoC',
      'FL-519' => 'Pasco County CoC',
      'VT-501' => 'Burlington/Chittenden County CoC',
      'WA-502' => 'Spokane City & County CoC',
      'WI-502' => 'Racine City & County CoC',
      'WV-501' => 'Huntington/Cabell, Wayne Counties CoC',
      'TX-700' => 'Houston, Pasadena, Conroe/Harris, Fort Bend, Montgomery Counties CoC',
      'WV-508' => 'West Virginia Balance of State CoC',
      'SC-502' => 'Columbia/Midlands CoC',
      'SD-500' => 'South Dakota Statewide CoC',
      'TN-500' => 'Chattanooga/Southeast Tennessee CoC',
      'OK-500' => 'North Central Oklahoma CoC',
      'AL-502' => 'Florence/Northwest Alabama CoC',
      'CA-604' => 'Bakersfield/Kern County CoC',
      'MA-500' => 'Boston CoC',
      'MA-511' => 'Quincy, Brockton, Weymouth, Plymouth City and County CoC',
      'TN-510' => 'Murfreesboro/Rutherford County CoC',
      'TX-500' => 'San Antonio/Bexar County CoC',
      'TX-503' => 'Austin/Travis County CoC',
      'TX-601' => 'Fort Worth, Arlington/Tarrant County CoC',
      'TX-604' => 'Waco/McLennan County CoC',
      'TX-607' => 'Texas Balance of State CoC',
      'PA-510' => 'Lancaster City & County CoC',
      'PA-511' => 'Bristol, Bensalem/Bucks County CoC',
      'PA-601' => 'Western Pennsylvania CoC',
      'PA-605' => 'Erie City & County CoC',
      'PR-502' => 'Puerto Rico Balance of Commonwealth CoC',
      'PR-503' => 'South-Southeast Puerto Rico CoC',
      'SC-500' => 'Charleston/Low Country CoC',
      'SC-501' => 'Greenville, Anderson, Spartanburg/Upstate CoC',
      'OK-505' => 'Northeast Oklahoma CoC',
      'OK-504' => 'Norman/Cleveland County CoC',
      'OK-506' => 'Southwest Oklahoma Regional CoC',
      'OR-500' => 'Eugene, Springfield/Lane County CoC',
      'OR-502' => 'Medford, Ashland/Jackson County CoC',
      'OR-505' => 'Oregon Balance of State CoC',
      'VA-507' => 'Portsmouth CoC',
      'VA-513' => 'Harrisonburg, Winchester/Western Virginia CoC',
      'VA-514' => 'Fredericksburg/Spotsylvania, Stafford Counties CoC',
      'VA-601' => 'Fairfax County CoC',
      'VA-603' => 'Alexandria CoC',
      'VT-500' => 'Vermont Balance of State CoC',
      'WA-500' => 'Seattle/King County CoC',
      'WA-504' => 'Everett/Snohomish County CoC',
      'WV-503' => 'Charleston/Kanawha, Putnam, Boone, Clay Counties CoC',
      'NY-522' => 'Jefferson, Lewis, St. Lawrence Counties CoC',
      'TX-611' => 'Amarillo CoC',
      'TX-701' => 'Bryan, College Station/Brazos Valley CoC',
      'UT-500' => 'Salt Lake City & County CoC',
      'UT-504' => 'Provo/Mountainland CoC',
      'VA-501' => 'Norfolk/Chesapeake, Suffolk, Isle of Wight, Southampton Counties CoC',
      'VA-502' => 'Roanoke City & County, Salem CoC',
      'MD-509' => 'Frederick City & County CoC',
      'AR-504' => 'Delta Hills CoC',
      'AZ-500' => 'Arizona Balance of State CoC',
      'FL-601' => 'Ft Lauderdale/Broward County CoC',
      'MA-505' => 'New Bedford CoC',
      'MA-517' => 'Somerville CoC',
      'NJ-503' => 'Camden City & County/Gloucester, Cape May, Cumberland Counties CoC',
      'NJ-501' => 'Bergen County CoC',
      'MD-512' => 'Hagerstown/Washington County CoC',
      'ME-500' => 'Maine Balance of State CoC',
      'MI-507' => 'Portage, Kalamazoo City & County CoC',
      'MI-516' => 'Norton Shores, Muskegon City & County CoC',
      'MN-509' => 'Duluth/St. Louis County CoC',
      'NJ-510' => 'Lakewood Township/Ocean County CoC',
      'MO-501' => 'St. Louis City CoC',
      'NY-603' => 'Nassau, Suffolk Counties CoC',
      'WA-503' => 'Tacoma, Lakewood/Pierce County CoC',
      'WA-507' => 'Yakima City & County CoC',
      'WI-500' => 'Wisconsin Balance of State CoC',
      'WI-501' => 'Milwaukee City & County CoC',
      'NY-601' => 'Poughkeepsie/Dutchess County CoC',
      'MA-508' => 'Lowell CoC',
      'CA-607' => 'Pasadena CoC',
      'FL-502' => 'St. Petersburg, Clearwater, Largo/Pinellas County CoC',
      'FL-503' => 'Lakeland, Winterhaven/Polk County CoC',
      'FL-506' => 'Tallahassee/Leon County CoC',
      'FL-508' => 'Gainesville/Alachua, Putnam Counties CoC',
      'FL-511' => 'Pensacola/Escambia, Santa Rosa Counties CoC',
      'FL-513' => 'Palm Bay, Melbourne/Brevard County CoC',
      'AK-500' => 'Anchorage CoC',
      'AL-500' => 'Birmingham/Jefferson, St. Clair, Shelby Counties CoC',
      'PA-600' => 'Pittsburgh, McKeesport, Penn Hills/Allegheny County CoC',
      'FL-500' => 'Sarasota, Bradenton/Manatee, Sarasota Counties CoC',
      'FL-518' => 'Columbia, Hamilton, Lafayette, Suwannee Counties CoC',
      'MA-503' => 'Cape Cod Islands CoC',
      'MA-507' => 'Pittsfield/Berkshire, Franklin, Hampshire Counties CoC',
      'CA-609' => 'San Bernardino City & County CoC',
      'CA-611' => 'Oxnard, San Buenaventura/Ventura County CoC',
      'DE-500' => 'Delaware Statewide CoC',
      'MT-500' => 'Montana Statewide CoC',
      'NC-501' => 'Asheville/Buncombe County CoC',
      'NC-504' => 'Greensboro, High Point CoC',
      'OH-501' => 'Toledo/Lucas County CoC',
      'MI-506' => 'Grand Rapids, Wyoming/Kent County CoC',
      'OR-501' => 'Portland, Gresham/Multnomah County CoC',
      'PA-504' => 'Lower Merion, Norristown, Abington/Montgomery County CoC',
      'GA-508' => 'DeKalb County CoC',
      'OH-504' => 'Youngstown/Mahoning County CoC',
      'OH-508' => 'Canton, Massillon, Alliance/Stark County CoC',
      'OK-507' => 'Southeastern Oklahoma Regional CoC',
      'NC-509' => 'Gastonia/Cleveland, Gaston, Lincoln Counties CoC',
      'NE-502' => 'Lincoln CoC',
      'AR-501' => 'Fayetteville/Northwest Arkansas CoC',
      'CA-509' => 'Mendocino County CoC',
      'CA-519' => 'Chico, Paradise/Butte County CoC',
      'CA-521' => 'Davis, Woodland/Yolo County CoC',
      'CA-524' => 'Yuba City & County/Sutter County CoC',
      'CA-526' => 'Tuolumne, Amador, Calaveras, Mariposa Counties CoC',
      'CA-602' => 'Santa Ana, Anaheim/Orange County CoC',
      'CA-606' => 'Long Beach CoC',
      'CT-503' => 'Bridgeport, Stamford, Norwalk/Fairfield County CoC',
      'CA-507' => 'Marin County CoC',
      'CA-510' => 'Turlock, Modesto/Stanislaus County CoC',
      'CA-513' => 'Visalia/Kings, Tulare Counties CoC',
      'CA-515' => 'Roseville, Rocklin/Placer, Nevada Counties CoC',
      'CA-518' => 'Vallejo/Solano County CoC',
      'MN-506' => 'Northwest Minnesota CoC',
      'AZ-502' => 'Phoenix, Mesa/Maricopa County CoC',
      'MI-508' => 'Lansing, East Lansing/Ingham County CoC',
      'MI-518' => 'Livingston County CoC',
      'MI-519' => 'Holland/Ottawa County CoC',
      'DC-500' => 'District of Columbia CoC',
      'WI-503' => 'Madison/Dane County CoC',
      'CA-500' => 'San Jose/Santa Clara City & County CoC',
      'CA-503' => 'Sacramento City & County CoC',
      'FL-517' => 'Hendry, Hardee, Highlands Counties CoC',
      'FL-602' => 'Punta Gorda/Charlotte County CoC',
      'FL-604' => 'Monroe County CoC',
      'GA-500' => 'Atlanta CoC',
      'MO-600' => 'Springfield/Greene, Christian, Webster Counties CoC',
      'MO-603' => 'St. Joseph/Andrew, Buchanan, DeKalb Counties CoC',
      'NJ-515' => 'Elizabeth/Union County CoC',
      'NY-512' => 'Troy/Rensselaer County CoC',
      'NY-518' => 'Utica, Rome/Oneida, Madison Counties CoC',
      'MS-500' => 'Jackson/Rankin, Madison Counties CoC',
      'NC-500' => 'Winston-Salem/Forsyth County CoC',
      'NY-507' => 'Schenectady City & County CoC',
      'NY-514' => 'Jamestown, Dunkirk/Chautauqua County CoC',
      'NV-501' => 'Reno, Sparks/Washoe County CoC',
      'CA-522' => 'Humboldt County CoC',
      'CA-525' => 'El Dorado County CoC',
      'CA-529' => 'Lake County CoC',
      'CA-600' => 'Los Angeles City & County CoC',
      'CA-601' => 'San Diego City and County CoC',
      'MD-507' => 'Cecil County CoC',
      'MD-508' => 'Charles, Calvert, St. Mary\'s Counties CoC',
      'MD-511' => 'Mid-Shore Regional CoC',
      'MD-600' => 'Prince George\'s County CoC',
      'MI-500' => 'Michigan Balance of State CoC',
      'MI-502' => 'Dearborn, Dearborn Heights, Westland/Wayne County CoC',
      'MI-503' => 'St. Clair Shores, Warren/Macomb County CoC',
      'MI-515' => 'Monroe City & County CoC',
      'VA-504' => 'Charlottesville CoC',
      'VA-505' => 'Newport News, Hampton/Virginia Peninsula CoC',
      'IL-506' => 'Joliet, Bolingbrook/Will County CoC',
      'SC-503' => 'Myrtle Beach, Sumter City & County CoC',
      'TN-503' => 'Central Tennessee CoC',
      'TN-506' => 'Upper Cumberland CoC',
      'TN-501' => 'Memphis/Shelby County CoC',
      'VA-600' => 'Arlington County CoC',
      'IN-503' => 'Indianapolis CoC',
      'TN-507' => 'Jackson/West Tennessee CoC',
      'VA-508' => 'Lynchburg CoC',
      'OR-506' => 'Hillsboro, Beaverton/Washington County CoC',
      'PA-603' => 'Beaver County CoC',
      'VA-521' => 'Virginia Balance of State CoC',
      'VA-602' => 'Loudoun County CoC',
      'VA-604' => 'Prince William County CoC',
      'WA-501' => 'Washington Balance of State CoC',
      'WY-500' => 'Wyoming Statewide CoC',
      'MN-511' => 'Southwest Minnesota CoC',
      'WA-508' => 'Vancouver/Clark County CoC',
      'NE-501' => 'Omaha, Council Bluffs CoC',
      'IL-508' => 'East St. Louis, Belleville/St. Clair County CoC',
      'IL-509' => 'DeKalb City & County CoC',
      'IL-513' => 'Springfield/Sangamon County CoC',
      'KY-500' => 'Kentucky Balance of State CoC',
      'KY-501' => 'Louisville-Jefferson County CoC',
      'MA-506' => 'Worcester City & County CoC',
      'MA-515' => 'Fall River CoC',
      'MD-500' => 'Cumberland/Allegany County CoC',
      'MD-503' => 'Annapolis/Anne Arundel County CoC',
      'MD-506' => 'Carroll County CoC',
      'TN-512' => 'Morristown/Blount, Sevier, Campbell, Cocke Counties CoC',
      'TX-600' => 'Dallas City & County, Irving CoC',
      'TX-603' => 'El Paso City & County CoC',
      'TX-624' => 'Wichita Falls/Wise, Palo Pinto, Wichita, Archer Counties CoC',
      'UT-503' => 'Utah Balance of State CoC',
      'VA-500' => 'Richmond/Henrico, Chesterfield, Hanover Counties CoC',
    }
    unless Rails.env.production?
      codes.merge!(
        {
          'XX-500' => 'Test CoC',
          'XX-501' => '2nd Test CoC',
        },
      )
    end
    codes.freeze
  end

  def cocs_in_state(state)
    return cocs if state.blank?

    cocs.select { |code, _| code.starts_with?(state) }
  end

  # This value indicates that the field is null if the column is non-nullable
  def ignored_enum_value
    999
  end
end
