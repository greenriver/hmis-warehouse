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
      'RaceNone' => 'None', # 6 (can be 99, 8, 9, null only if all other race fields are 99 or 0)
    }
    race_list['MultiRacial'] = 'Multi-Racial' if multi_racial
    race_list
  end

  # for translating straight from a controlled vocabulary list identifier and integer
  # to the corresponding phrase
  def list(number, id, reverse = false)
    method = case number.to_s
    when 'race' then :race
    when '1.1' then :export_period_type
    when '1.2' then :export_directive
    when '1.3' then :disability_type
    when '1.4' then :record_type
    when '1.5' then :hash_status
    when '1.6' then :race_none
    when '1.7' then :no_yes_missing
    when '1.8' then :no_yes_reasons_for_missing_data
    when '1.9' then :source_type
    when '2.4.2' then :project_type
    when '2.5.1' then :tracking_method
    when '2.6.1' then :funding_source
    when '2.7.2' then :household_type
    when '2.7.3' then :bed_type
    when '2.7.4' then :availability
    when '2.7.B' then :youth_age_group
    when '2.8.7' then :geography_type
    when '2.8.8' then :housing_type
    when '2.9.1' then :target_population
    when '3.1.5' then :name_data_quality
    when '3.2.2' then :ssn_data_quality
    when '3.3.2' then :dob_data_quality
    when '3.5.1' then :ethnicity
    when '3.6.1' then :gender
    when '3.917.1' then :living_situation
    when '3.917.2' then :residence_prior_length_of_stay
    when '3.3917.4' then :times_homeless_past_three_years
    when '3.917.5' then :months_homeless_past_three_years
    when '3.12.1' then :destination
    when '3.15.1' then :relationship_to_hoh
    when '4.1.1' then :housing_status
    when '4.04.A' then :reason_not_insured
    when '4.9.D' then :p_a_t_h_how_confirmed
    when '4.9.E' then :p_a_t_h_s_m_i_information
    when '4.10.2' then :disability_response
    when '4.11.A' then :when_d_v_occurred
    when '4.12.2' then :contact_location
    when '4.14.A', 'P1.2' then :p_a_t_h_services
    when '4.14.B' then :r_h_y_services
    when '4.14.C', 'W1.2' then :h_o_p_w_a_services
    when '4.14.D', 'V2.2' then :s_s_v_f_services
    when '4.14.D3', 'V2.A' then :s_s_v_f_sub_type3
    when '4.14.D4', 'V2.4', 'V2.B' then :s_s_v_f_sub_type4
    when '4.14.D5', 'V2.5', 'V2.C' then :s_s_v_f_sub_type5
    when '4.15.A', 'V2.3' then :h_o_p_w_a_financial_assistance
    when '4.14' then :bed_night
    when '4.15.B' then :s_s_v_f_financial_assistance
    when '4.16.A', 'P2.2' then :p_a_t_h_referral
    when '4.16.B', 'R14.2' then :r_h_y_referral
    when '4.16.A1' then :p_a_t_h_referral_outcome
    when '4.18.1' then :housing_assessment_disposition
    when '4.19.1', 'W5.1' then :housing_assessment_at_exit
    when '4.19.3' then :assessment_type
    when '4.19.4' then :assessment_level
    when '4.19.7' then :prioritization_status
    when '4.19.A', 'W5.A' then :subsidy_information
    when '4.20.A', 'P3.A' then :reason_not_enrolled
    when '4.20.D' then :referral_result
    when '4.20.2' then :event
    when '4.22.A', 'R2.A' then :reason_no_services
    when '4.23.1', 'R3.1' then :sexual_orientation
    when '4.24.1', 'R4.1' then :last_grade_completed
    when '4.25.1', 'R5.1' then :school_status
    when '4.26.A', 'R6.A' then :employment_type
    when '4.26.B', 'R6.B' then :not_employed_reason
    when '4.27.1', 'R7.1' then :health_status
    when '4.31.A', 'R11.A' then :r_h_y_numberof_years
    when '4.33.A' then :incarcerated_parent_status
    when '4.34.1', 'R1.1' then :referral_source
    when '4.35.A', 'R15.B' then :count_exchange_for_sex
    when '4.36.1' then :exit_action
    when '4.37.1', 'R17.1' then :project_completion_status
    when '4.37.A' then :early_exit_reason
    when '4.37.B', 'R17.A' then :expelled_reason
    when 'R19.A' then :worker_response
    when 'R20.2' then :aftercare_provided
    when '4.39', 'W3' then :no_assistance_reason
    when '4.41.11', 'V1.11' then :military_branch
    when '4.41.12', 'V1.12' then :discharge_status
    when '4.42.1', 'V4.1' then :percent_a_m_i
    when '4.43.5', 'V5.5' then :address_data_quality
    when 'V6.1' then :vamcs_station_number
    when '4.47.B', 'W4.B' then :t_cell_source_viral_load_source
    when '4.47.3', 'W4.3' then :viral_load_available
    when '4.48.1', 'V7.1' then :no_points_yes
    when '4.48.2', 'V7.2', 'V7.A' then :time_to_housing_loss
    when '4.48.4', 'V7.4', 'V7.B' then :annual_percent_a_m_i
    when '4.48.7', 'V7.7', 'V7.G' then :eviction_history
    when '4.48.9', 'V7.9', 'V7.C' then :literal_homeless_history
    when 'V7.I' then :incarcerated_adult
    when 'V7.O' then :dependent_under_6
    when 'V8.1' then :voucher_tracking
    when 'V9.1' then :cm_exit_reason
    when '4.49.1' then :crisis_services_use
    when '5.03.1' then :data_collection_stage
    when 'ad_hoc_yes_no_1' then :ad_hoc_yes_no_1
    when 'C1.1' then :wellbeing_agreement
    when 'C1.2' then :feeling_frequency
    when 'C2.2' then :moving_on_assistance
    when 'C3.2' then :current_school_attended
    when 'C3.A' then :most_recent_ed_status
    when 'C3.B' then :current_ed_status
    else
      raise "unknown controlled vocabulary list: #{number}"
    end
    send method, id, reverse
  end

  # 1.1
  def export_period_type(id, reverse = false)
    map = period_types

    _translate map, id, reverse
  end

  def period_types
    {
      1 => 'Updated',
      2 => 'Effective',
      3 => 'Reporting period',
      4 => 'Other',
    }.freeze
  end

  # 1.2
  def export_directive(id, reverse = false)
    map = export_directives

    _translate map, id, reverse
  end

  def export_directives
    {
      1 => 'Delta refresh',
      2 => 'Full refresh',
      3 => 'Other',
    }.freeze
  end

  # 1.3
  def disability_type(id, reverse = false)
    map = disability_types
    _translate map, id, reverse
  end

  def disability_types
    {
      5 => 'Physical disability',
      6 => 'Developmental disability',
      7 => 'Chronic health condition',
      8 => 'HIV/AIDS',
      9 => 'Mental health disorder',
      10 => 'Substance use disorder',
    }
  end

  # 1.4
  def record_type(id, reverse = false)
    map = record_types

    _translate map, id, reverse
  end

  def record_types
    {
      12 => 'Contact', # removed in 2020 spec
      13 => 'Contact', # removed in 2020 spec
      141 => 'PATH service',
      142 => 'RHY service connections',
      143 => 'HOPWA service',
      144 => 'SSVF service',
      151 => 'HOPWA financial assistance',
      152 => 'SSVF financial assistance',
      161 => 'PATH referral',
      162 => 'RHY referral',
      200 => 'Bed night',
      210 => 'HUD-VASH OTH voucher tracking',
    }.freeze
  end

  # 1.5
  def hash_status(id, reverse = false)
    map = hash_statuses

    _translate map, id, reverse
  end

  def hash_statuses
    {
      1 => 'Unhashed',
      2 => 'SHA-1 RHY',
      3 => 'Hashed - other',
      4 => 'SHA-256 (RHY)',
    }.freeze
  end

  # 1.6
  def race_none(id, reverse = false)
    map = {
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 1.7
  def no_yes_missing(id, reverse = false)
    map = yes_no_missing_options

    _translate map, id, reverse
  end

  def yes_no_missing_options
    {
      0 => 'No',
      1 => 'Yes',
      99 => 'Data not collected*',
    }
  end

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
    {
      0 => 'No',
      1 => 'Yes',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }
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
    {
      1 => 'CoC HMIS',
      2 => 'Standalone/agency-specific application',
      3 => 'Data warehouse',
      4 => 'Other',
    }.freeze
  end

  # 2.4.2
  def project_type(id, reverse = false, translate = true)
    map = project_types
    if translate
      _translate map, id, reverse
    else
      map
    end
  end

  def project_types
    {
      1 => 'Emergency Shelter',
      2 => 'Transitional Housing',
      3 => 'PH - Permanent Supportive Housing',
      4 => 'Street Outreach',
      6 => 'Services Only',
      7 => 'Other',
      8 => 'Safe Haven',
      9 => 'PH - Housing Only',
      10 => 'PH - Housing with Services (no disability required for entry)',
      11 => 'Day Shelter',
      12 => 'Homelessness Prevention',
      13 => 'PH - Rapid Re-Housing',
      14 => 'Coordinated Assessment',
    }
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
      'Coordinated Assessment'
    end
  end

  # 2.5.1 / 2.02.C
  def tracking_method(id, reverse = false)
    map = tracking_methods

    _translate map, id, reverse
  end

  def tracking_methods
    {
      0 => 'Entry/Exit Date',
      3 => 'Night-by-Night',
      nil => 'Entry/Exit Date',
    }
  end

  def funding_sources
    {
      1 => 'HUD: CoC - Homelessness Prevention (High Performing Communities Only)',
      2 => 'HUD: CoC - Permanent Supportive Housing',
      3 => 'HUD: CoC - Rapid Re-Housing',
      4 => 'HUD: CoC - Supportive Services Only',
      5 => 'HUD: CoC - Transitional Housing',
      6 => 'HUD: CoC - Safe Haven',
      7 => 'HUD: CoC - Single Room Occupancy (SRO)',
      8 => 'HUD: ESG - Emergency Shelter (operating and/or essential services)',
      9 => 'HUD: ESG - Homelessness Prevention ',
      10 => 'HUD: ESG - Rapid Rehousing',
      11 => 'HUD: ESG - Street Outreach',
      12 => 'HUD: Rural Housing Stability Assistance Program ',
      13 => 'HUD: HOPWA - Hotel/Motel Vouchers',
      14 => 'HUD: HOPWA - Housing Information',
      15 => 'HUD: HOPWA - Permanent Housing (facility based or TBRA)',
      16 => 'HUD: HOPWA - Permanent Housing Placement',
      17 => 'HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance',
      18 => 'HUD: HOPWA - Short-Term Supportive Facility',
      19 => 'HUD: HOPWA - Transitional Housing (facility based or TBRA)',
      20 => 'HUD: HUD/VASH',
      21 => 'HHS: PATH - Street Outreach & Supportive Services Only',
      22 => 'HHS: RHY - Basic Center Program (prevention and shelter)',
      23 => 'HHS: RHY - Maternity Group Home for Pregnant and Parenting Youth',
      24 => 'HHS: RHY - Transitional Living Program',
      25 => 'HHS: RHY - Street Outreach Project',
      26 => 'HHS: RHY - Demonstration Project',
      27 => 'VA: CRS Contract Residential Services',
      30 => 'VA: Community Contract Safe Haven Program',
      32 => 'VA: Compensated Work Therapy Transitional Residence',
      33 => 'VA: Supportive Services for Veteran Families',
      34 => 'N/A',
      35 => 'HUD: Pay for Success',
      36 => 'HUD: Public and Indian Housing (PIH) Programs',
      37 => 'VA: Grant Per Diem - Bridge Housing',
      38 => 'VA: Grant Per Diem - Low Demand',
      39 => 'VA: Grant Per Diem - Hospital to Housing',
      40 => 'VA: Grant Per Diem - Clinical Treatment',
      41 => 'VA: Grant Per Diem - Service Intensive Transitional Housing',
      42 => 'VA: Grant Per Diem - Transition in Place',
      43 => 'HUD: CoC - Youth Homeless Demonstration Program (YHDP)',
      44 => 'HUD: CoC - Joint Component TH/RRH',
      45 => 'VA: Grant Per Diem - Case Management/Housing Retention',
      46 => 'Local or Other Funding Source',
      47 => 'HUD: ESG – CV',
      48 => 'HUD: HOPWA – CV',
      49 => 'HUD: CoC – Joint Component RRH/PSH ',
      50 => 'HUD: HOME',
      51 => 'HUD: HOME (ARP)',
      52 => 'HUD: PIH (Emergency Housing Voucher)',
    }
  end

  # 2.6.1
  def funding_source(id, reverse = false)
    map = funding_sources
    _translate map, id, reverse
  end

  # 2.7.2
  def household_type(id, reverse = false)
    map = household_types

    _translate map, id, reverse
  end

  def household_types
    {
      1 => 'Households without children',
      3 => 'Households with at least one adult and one child',
      4 => 'Households with only children',
    }.freeze
  end

  # 2.7.3
  def bed_type(id, reverse = false)
    map = bed_types

    _translate map, id, reverse
  end

  def bed_types
    {
      1 => 'Facility-based',
      2 => 'Voucher',
      3 => 'Other',
    }
  end

  # 2.7.4
  def availability(id, reverse = false)
    map = availabilities

    _translate map, id, reverse
  end

  def availabilities
    {
      1 => 'Year-round',
      2 => 'Seasonal',
      3 => 'Overflow',
    }.freeze
  end

  # 2.7.B
  def youth_age_group(id, reverse = false)
    map = {
      1 => 'Only under age 18',
      2 => 'Only ages 18 to 24',
      3 => 'Only youth under age 24 (both of the above)',
    }

    _translate map, id, reverse
  end

  # 2.8.7
  def geography_type(id, reverse = false)
    map = geography_types

    _translate map, id, reverse
  end

  def geography_types
    {
      1 => 'Urban',
      2 => 'Suburban',
      3 => 'Rural',
      99 => 'Unknown / data not collected',
    }
  end

  # 2.8.8 / 2.02.D
  def housing_type(id, reverse = false)
    map = housing_types

    _translate map, id, reverse
  end

  def housing_types
    {
      1 => 'Site-based - single site',
      2 => 'Site-based - clustered / multiple sites',
      3 => 'Tenant-based - scattered site',
    }
  end

  # 2.9.1 / 2.02.8
  def target_population(id, reverse = false)
    map = target_populations

    _translate map, id, reverse
  end

  def target_populations
    {
      1 => 'Domestic violence victims',
      3 => 'Persons with HIV/AIDS',
      4 => 'Not applicable',
    }
  end

  # 2.02.9
  def h_o_p_w_a_med_assisted_living_fac(id, reverse = false)
    map = h_o_p_w_a_med_assisted_living_facs

    _translate map, id, reverse
  end

  def h_o_p_w_a_med_assisted_living_facs
    {
      0 => 'No',
      1 => 'Yes',
      2 => 'Non-HOPWA Funded Project',
    }
  end

  # 3.1.5
  def name_data_quality(id, reverse = false)
    _translate(name_data_quality_options, id, reverse)
  end

  def name_data_quality_options
    {
      1 => 'Full name reported',
      2 => 'Partial, street name, or code name reported',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }
  end

  # 3.2.2
  def ssn_data_quality(id, reverse = false)
    _translate(ssn_data_quality_options, id, reverse)
  end

  def ssn_data_quality_options
    {
      1 => 'Full SSN reported',
      2 => 'Approximate or partial SSN reported',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }
  end

  # 3.3.2
  def dob_data_quality(id, reverse = false)
    map = dob_data_quality_options

    _translate map, id, reverse
  end

  def dob_data_quality_options
    {
      1 => 'Full DOB reported',
      2 => 'Approximate or partial DOB reported',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 3.5.1
  def ethnicity(id, reverse = false)
    map = ethnicities

    _translate map, id, reverse
  end

  def ethnicities
    {
      0 => 'Non-Hispanic/Non-Latin(a)(o)(x)',
      1 => 'Hispanic/Latin(a)(o)(x)',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }
  end

  # 3.6.1
  def gender(id, reverse = false)
    map = genders
    _translate map, id, reverse
  end

  def genders
    {
      0 => 'Female',
      1 => 'Male',
      4 => 'A gender other than singularly female or male (e.g., non-binary, genderfluid, agender, culturally specific gender)',
      5 => 'Transgender',
      6 => 'Questioning',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  def gender_fields
    [
      :Female,
      :Male,
      :NoSingleGender,
      :Transgender,
      :Questioning,
      :GenderNone,
    ]
  end

  def gender_id_to_field_name
    {
      0 => 'Female',
      1 => 'Male',
      4 => 'NoSingleGender',
      5 => 'Transgender',
      6 => 'Questioning',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
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
      '0,1,4,5',
      '0,1,4',
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
    available_living_situations = available_situations
    available_living_situations[27] = 'Interim Housing' # for backwards compatibility
    available_living_situations
  end

  # 3.917.2
  def residence_prior_length_of_stay(id, reverse = false)
    map = length_of_stays

    _translate map, id, reverse
  end

  def length_of_stays
    {
      2 => 'One week or more, but less than one month',
      3 => 'One month or more, but less than 90 days',
      4 => '90 days or more but less than one year',
      5 => 'One year or longer',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      10 => 'One night or less',
      11 => 'Two to six nights',
      99 => 'Data not collected',
    }.freeze
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
    {
      1 => 'One time',
      2 => 'Two times',
      3 => 'Three times',
      4 => 'Four or more times',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
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
      113 => '12+',
    }

    _translate map, id, reverse
  end

  def month_categories
    {
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
      101 => '1',
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
      113 => 'More than 12 months',
    }
  end

  # 3.12.1
  def destination(id, reverse = false)
    map = valid_destinations

    _translate map, id, reverse
  end

  def valid_destinations
    available_situations
  end

  def available_situations
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
    when '2020', nil
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
    when '2020', nil
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
    when '2020', nil
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
    when '2020', nil # From SPM 3.1 definition
      [
        1,
        15,
        14,
        27,
        4,
        18,
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

  # 3.15.1
  def relationship_to_hoh(id, reverse = false)
    map = relationships_to_hoh

    _translate map, id, reverse
  end

  def relationships_to_hoh
    {
      1 => 'Self (head of household)',
      2 => 'Child',
      3 => 'Spouse or partner',
      4 => 'Other relative',
      5 => 'Unrelated household member',
      99 => 'Data not collected',
    }
  end

  # 4.1.1
  def housing_status(id, reverse = false)
    map = {
      1 => 'Category 1 - Homeless',
      2 => 'Category 2 - At imminent risk of losing housing',
      3 => 'At-risk of homelessness',
      4 => 'Stably housed',
      5 => 'Category 3 - Homeless only under other federal statutes',
      6 => 'Category 4 - Fleeing domestic violence',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.04.A
  def reason_not_insured(id, reverse = false)
    map = {
      1 => 'Applied; decision pending',
      2 => 'Applied; client not eligible',
      3 => 'Client did not apply',
      4 => 'Insurance type N/A for this client',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.9.D
  def p_a_t_h_how_confirmed(id, reverse = false)
    map = {
      1 => 'Unconfirmed; presumptive or self-report',
      2 => 'Confirmed through assessment and clinical evaluation',
      3 => 'Confirmed by prior evaluation or clinical records',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.9.E
  def p_a_t_h_s_m_i_information(id, reverse = false)
    map = {
      0 => 'No',
      1 => 'Unconfirmed; presumptive or self-report',
      2 => 'Confirmed through assessment and clinical evaluation',
      3 => 'Confirmed by prior evaluation or clinical records',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.10.2
  def disability_response(id, reverse = false)
    map = disability_responses

    _translate map, id, reverse
  end

  def disability_responses
    {
      0 => 'No',
      1 => 'Alcohol use disorder',
      2 => 'Drug use disorder',
      3 => 'Both alcohol and drug use disorders',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 4.11.A
  def when_d_v_occurred(id, reverse = false)
    map = when_occurreds
    _translate map, id, reverse
  end

  def when_occurreds
    {
      1 => 'Within the past three months',
      2 => 'Three to six months ago (excluding six months exactly)',
      3 => 'Six months to one year ago (excluding one year exactly)',
      4 => 'One year or more',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }
  end

  # 4.12.2
  def contact_location(id, reverse = false)
    map = {
      1 => 'Place not meant for habitation',
      2 => 'Service setting, non-residential',
      3 => 'Service setting, residential',
    }

    _translate map, id, reverse
  end

  # 4.14.A / P1.2
  def p_a_t_h_services(id, reverse = false)
    map = {
      1 => 'Re-engagement',
      2 => 'Screening',
      3 => 'Habilitation/rehabilitation',
      4 => 'Community mental health',
      5 => 'Substance use treatment',
      6 => 'Case management',
      7 => 'Residential supportive services',
      8 => 'Housing minor renovation',
      9 => 'Housing moving assistance',
      10 => 'Housing eligibility determination',
      11 => 'Security deposits',
      12 => 'One-time rent for eviction prevention',
      14 => 'Clinical assessment',
    }

    _translate map, id, reverse
  end

  # 4.14.B / R14.2
  def r_h_y_services(id, reverse = false)
    map = {
      # 1 => 'Basic support services',
      2 => 'Community service/service learning (CSL)',
      # 3 => 'Counseling/therapy',
      # 4 => 'Dental care',
      5 => 'Education',
      6 => 'Employment and training services',
      7 => 'Criminal justice /legal services',
      8 => 'Life skills training',
      # 9 => 'Parenting education for parent of youth',
      10 => 'Parenting education for youth with children',
      # 11 => 'Peer (youth) counseling',
      12 => 'Post-natal care',
      13 => 'Pre-natal care',
      14 => 'Health/medical care',
      # 15 => 'Psychological or psychiatric care',
      # 16 => 'Recreational activities',
      17 => 'Substance use disorder treatment',
      18 => 'Substance use disorder/Prevention Services',
      # 19 => 'Support group',
      # 20 => 'Preventative - overnight interim, respite',
      # 21 => 'Preventative - formal placement in an alternative setting outside of BCP',
      # 22 => 'Preventative - entry into BCP after preventative services',
      # 23 => 'Street outreach - health and hygiene products distributed',
      # 24 => 'Street outreach - food and drink items',
      # 25 => 'Street outreach - services information/brochures',
      26 => 'Home-based Services',
      27 => 'Post-natal newborn care (wellness exams; immunizations)',
      28 => 'STD Testing',
      29 => 'Street-based Services',
    }

    _translate map, id, reverse
  end

  # 4.14.C, W1.2
  def h_o_p_w_a_services(id, reverse = false)
    map = {
      1 => 'Adult day care and personal assistance',
      2 => 'Case management',
      3 => 'Child care',
      4 => 'Criminal justice/legal services',
      5 => 'Education',
      6 => 'Employment and training services',
      7 => 'Food/meals/nutritional services',
      8 => 'Health/medical care',
      9 => 'Life skills training',
      10 => 'Mental health care/counseling',
      11 => 'Outreach and/or engagement',
      12 => 'Substance abuse services/treatment',
      13 => 'Transportation',
      14 => 'Other HOPWA funded service',
    }

    _translate map, id, reverse
  end

  # 4.14.D / V2.2
  def s_s_v_f_services(id, reverse = false)
    map = {
      1 => 'Outreach services',
      2 => 'Case management services',
      3 => 'Assistance obtaining VA benefits',
      4 => 'Assistance obtaining/coordinating other public benefits',
      5 => 'Direct provision of other public benefits',
      6 => 'Other (non-TFA) supportive service approved by VA',
    }

    _translate map, id, reverse
  end

  # 4.14.D3 / V2.A
  def s_s_v_f_sub_type3(id, reverse = false)
    map = {
      1 => 'VA vocational and rehabilitation counseling',
      2 => 'Employment and training services',
      3 => 'Educational assistance',
      4 => 'Health care services',
    }

    _translate map, id, reverse
  end

  # 4.14.D4 / V2.4 / V2.B
  def s_s_v_f_sub_type4(id, reverse = false)
    map = {
      1 => 'Health care services',
      2 => 'Daily living services',
      3 => 'Personal financial planning services',
      4 => 'Transportation services',
      5 => 'Income support services',
      6 => 'Fiduciary and representative payee services',
      7 => 'Legal services - child support',
      8 => 'Legal services - eviction prevention',
      9 => 'Legal services - outstanding fines and penalties',
      10 => 'Legal services - restore / acquire driver\'s license',
      11 => 'Legal services - other',
      12 => 'Child care',
      13 => 'Housing counseling',
    }

    _translate map, id, reverse
  end

  # 4.14.D5 / V2.5 / V2.C
  def s_s_v_f_sub_type5(id, reverse = false)
    map = {
      1 => 'Personal financial planning services',
      2 => 'Transportation services',
      3 => 'Income support services',
      4 => 'Fiduciary and representative payee services',
      5 => 'Legal services - child support',
      6 => 'Legal services - eviction prevention',
      7 => 'Legal services - outstanding fines and penalties',
      8 => 'Legal services - restore / acquire driver\'s license',
      9 => 'Legal services - other',
      10 => 'Child care',
      11 => 'Housing counseling',
    }

    _translate map, id, reverse
  end

  # 4.15.A / W2.3
  def h_o_p_w_a_financial_assistance(id, reverse = false)
    map = {
      1 => 'Rental assistance',
      2 => 'Security deposits',
      3 => 'Utility deposits',
      4 => 'Utility payments',
      7 => 'Mortgage assistance',
    }

    _translate map, id, reverse
  end

  # 4.14
  def bed_night(id, reverse = false)
    map = {
      200 => 'BedNight',
    }

    _translate map, id, reverse
  end

  # 4.15.B / V3.3
  def s_s_v_f_financial_assistance(id, reverse = false)
    map = {
      1 => 'Rental assistance',
      2 => 'Security deposit',
      3 => 'Utility deposit',
      4 => 'Utility fee payment assistance',
      5 => 'Moving costs',
      8 => 'Transportation services: tokens/vouchers',
      9 => 'Transportation services: vehicle repair/maintenance',
      10 => 'Child care',
      11 => 'General housing stability assistance - emergency supplies', # Retired in 2022 (remove later)
      12 => 'General housing stability assistance',
      14 => 'Emergency housing assistance',
      15 => 'Extended Shallow Subsidy - Rental Assistance',
      16 => 'Food Assistance',
    }

    _translate map, id, reverse
  end

  # 4.16.A / P2.2
  def p_a_t_h_referral(id, reverse = false)
    map = {
      1 => 'Community mental health',
      2 => 'Substance use treatment',
      3 => 'Primary health/dental care',
      4 => 'Job training',
      5 => 'Educational services',
      6 => 'Housing services',
      7 => 'Permanent housing',
      8 => 'Income assistance',
      9 => 'Employment assistance',
      10 => 'Medical insurance',
      11 => 'Temporary housing',
    }

    _translate map, id, reverse
  end

  # 4.16.B
  def r_h_y_referral(id, reverse = false)
    map = {
      1 => 'Child care non-TANF',
      2 => 'Supplemental nutritional assistance program (food stamps)',
      3 => 'Education - McKinney/Vento liaison assistance to remain in school',
      4 => 'HUD section 8 or other permanent housing assistance',
      5 => 'Individual development account',
      6 => 'Medicaid',
      7 => 'Mentoring program other than RHY agency',
      8 => 'National service (Americorps, VISTA, Learn and Serve)',
      9 => 'Non-residential substance abuse or mental health program',
      10 => 'Other public - federal, state, or local program',
      11 => 'Private non-profit charity or foundation support',
      12 => 'SCHIP',
      13 => 'SSI, SSDI, or other disability insurance',
      14 => 'TANF or other welfare/non-disability income maintenance (all TANF services)',
      15 => 'Unemployment insurance',
      16 => 'WIC',
      17 => 'Workforce development (WIA)',
    }

    _translate map, id, reverse
  end

  # 4.16.A1 / P2.A
  def p_a_t_h_referral_outcome(id, reverse = false)
    map = {
      1 => 'Attained',
      2 => 'Not attained',
      3 => 'Unknown',
    }

    _translate map, id, reverse
  end

  # 4.18.1
  def housing_assessment_disposition(id, reverse = false)
    map = {
      1 => 'Referred to emergency shelter/safe haven',
      2 => 'Referred to transitional housing',
      3 => 'Referred to rapid re-housing',
      4 => 'Referred to permanent supportive housing',
      5 => 'Referred to homelessness prevention',
      6 => 'Referred to street outreach',
      7 => 'Referred to other continuum project type',
      8 => 'Referred to a homelessness diversion program',
      9 => 'Unable to refer/accept within continuum; ineligible for continuum projects',
      10 => 'Unable to refer/accept within continuum; continuum services unavailable',
      11 => 'Referred to other community project (non-continuum)',
      12 => 'Applicant declined referral/acceptance',
      13 => 'Applicant terminated assessment prior to completion',
      14 => 'Other/specify',
    }

    _translate map, id, reverse
  end

  # 4.19.1 / W5.1
  def housing_assessment_at_exit(id, reverse = false)
    map = {
      1 => 'Able to maintain the housing they had at project entry',
      2 => 'Moved to new housing unit',
      3 => 'Moved in with family/friends on a temporary basis',
      4 => 'Moved in with family/friends on a permanent basis',
      5 => 'Moved to a transitional or temporary housing facility or program',
      6 => 'Client became homeless - moving to a shelter or other place unfit for human habitation',
      7 => 'Client went to jail/prison',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      10 => 'Client died',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.19.3
  def assessment_type(id, reverse = false)
    map = assessment_types

    _translate map, id, reverse
  end

  def assessment_types
    {
      1 => 'Phone',
      2 => 'Virtual',
      3 => 'In Person',
    }.freeze
  end

  # 4.19.4
  def assessment_level(id, reverse = false)
    map = assessment_levels

    _translate map, id, reverse
  end

  def assessment_levels
    {
      1 => 'Crisis Needs Assessment',
      2 => 'Housing Needs Assessment',
    }.freeze
  end

  # 4.19.7
  def prioritization_status(id, reverse = false)
    map = prioritization_statuses

    _translate map, id, reverse
  end

  def prioritization_statuses
    {
      1 => 'Placed on prioritization list',
      2 => 'Not placed on prioritization list',
    }.freeze
  end

  # 4.19.A / W5.A
  def subsidy_information(id, reverse = false)
    map = {
      1 => 'Without a subsidy 1',
      2 => 'With the subsidy they had at project entry 1',
      3 => 'With an on-going subsidy acquired since project entry 1',
      4 => 'But only with other financial assistance 1',
      11 => 'With on-going subsidy 2',
      12 => 'Without an on-going subsidy 2',
    }

    _translate map, id, reverse
  end

  # 4.20.A / P3.A
  def reason_not_enrolled(id, reverse = false)
    map = {
      1 => 'Client was found ineligible for PATH',
      2 => 'Client was not enrolled for other reason(s)',
    }

    _translate map, id, reverse
  end

  # 4.20.2
  def event(id, reverse = false)
    map = events

    _translate map, id, reverse
  end

  def events
    {
      1 => 'Referral to Prevention Assistance project',
      2 => 'Problem Solving/Diversion/Rapid Resolution intervention or service',
      3 => 'Referral to scheduled Coordinated Entry Crisis Needs Assessment',
      4 => 'Referral to scheduled Coordinated Entry Housing Needs Assessment',
      5 => 'Referral to Post-placement/ follow-up case management',
      6 => 'Referral to Street Outreach project or services',
      7 => 'Referral to Housing Navigation project or services',
      8 => 'Referral to Non-continuum services: Ineligible for continuum services',
      9 => 'Referral to Non-continuum services: No availability in continuum services',
      10 => 'Referral to Emergency Shelter bed opening',
      11 => 'Referral to Transitional Housing bed/unit opening',
      12 => 'Referral to Joint TH-RRH project/unit/resource opening',
      13 => 'Referral to RRH project resource opening',
      14 => 'Referral to PSH project resource opening',
      15 => 'Referral to Other PH project/unit/resource opening',
      16 => 'Referral to emergency assistance/flex fund/furniture assistance',
      17 => 'Referral to Emergency Housing Voucher (EHV)',
      18 => 'Referral to a Housing Stability Voucher',
    }.freeze
  end

  # 4.20.D
  def referral_result(id, reverse = false)
    map = {
      1 => 'Successful referral: client accepted',
      2 => 'Unsuccessful referral: client rejected',
      3 => 'Unsuccessful referral: provider rejected',
    }

    _translate map, id, reverse
  end

  # 4.22.A / R2.A
  def reason_no_services(id, reverse = false)
    map = {
      1 => 'Out of age range',
      2 => 'Ward of the state',
      3 => 'Ward of the criminal justice system',
      4 => 'Other',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.23.1 / R3.1
  def sexual_orientation(id, reverse = false)
    map = {
      1 => 'Heterosexual',
      2 => 'Gay',
      3 => 'Lesbian',
      4 => 'Bisexual',
      5 => 'Questioning / unsure',
      6 => 'Other',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.24.1 / R4.1
  def last_grade_completed(id, reverse = false)
    map = {
      1 => 'Less than grade 5',
      2 => 'Grades 5-6',
      3 => 'Grades 7-8',
      4 => 'Grades 9-11',
      5 => 'Grade 12',
      6 => 'School program does not have grade levels',
      7 => 'GED',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      10 => 'Some college',
      11 => 'Associate\'s degree',
      12 => 'Bachelor\'s degree',
      13 => 'Graduate degree',
      14 => 'Vocational certification',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.25.1 / R5.1
  def school_status(id, reverse = false)
    map = {
      1 => 'Attending school regularly',
      2 => 'Attending school irregularly',
      3 => 'Graduated from high school',
      4 => 'Obtained GED',
      5 => 'Dropped out',
      6 => 'Suspended',
      7 => 'Expelled',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.26.A / R6.A
  def employment_type(id, reverse = false)
    map = {
      1 => 'Full-time',
      2 => 'Part-time',
      3 => 'Seasonal / sporadic (including day labor)',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.26.B / R6.B
  def not_employed_reason(id, reverse = false)
    map = {
      1 => 'Looking for work',
      2 => 'Unable to work',
      3 => 'Not looking for work',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.27.1 / R7.1
  def health_status(id, reverse = false)
    map = {
      1 => 'Excellent',
      2 => 'Very good',
      3 => 'Good',
      4 => 'Fair',
      5 => 'Poor',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.31.A / R11.A
  def r_h_y_numberof_years(id, reverse = false)
    map = {
      1 => 'Less than one year',
      2 => '1 to 2 years',
      3 => '3 to 5 or more years',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.33.A
  def incarcerated_parent_status(id, reverse = false)
    map = {
      1 => 'One parent / legal guardian is incarcerated',
      2 => 'Both parents / legal guardians are incarcerated',
      3 => 'The only parent / legal guardian is incarcerated',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.34.1 / R1.1
  def referral_source(id, reverse = false)
    map = {
      1 => 'Self-referral',
      2 => 'Individual: Parent/Guardian/Relative/Friend/Foster Parent/Other Individual',
      # 3 => 'Individual: relative or friend',
      # 4 => 'Individual: other adult or youth',
      # 5 => 'Individual: partner/spouse',
      # 6 => 'Individual: foster parent',
      7 => 'Outreach Project',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      10 => 'Outreach project: other',
      11 => 'Temporary Shelter',
      # 12 => 'Temporary shelter: other youth only emergency shelter',
      # 13 => 'Temporary shelter: emergency shelter for families',
      # 14 => 'Temporary shelter: emergency shelter for individuals',
      # 15 => 'Temporary shelter: domestic violence shelter',
      # 16 => 'Temporary shelter: safe place',
      # 17 => 'Temporary shelter: other',
      18 => 'Residential Project',
      # 19 => 'Residential project: other transitional living project',
      # 20 => 'Residential project: group home',
      # 21 => 'Residential project: independent living project',
      # 22 => 'Residential project: job corps',
      # 23 => 'Residential project: drug treatment center',
      # 24 => 'Residential project: treatment center',
      # 25 => 'Residential project: educational institute',
      # 26 => 'Residential project: other agency project',
      # 27 => 'Residential project: other project',
      28 => 'Hotline',
      # 29 => 'Hotline: other',
      30 => 'Child Welfare/CPS',
      # 31 => 'Other agency: non-residential independent living project',
      # 32 => 'Other project operated by your agency',
      # 33 => 'Other youth services agency',
      34 => 'Juvenile Justice',
      35 => 'Law Enforcement/ Police',
      # 36 => 'Religious organization',
      37 => 'Mental Hospital',
      38 => 'School',
      39 => 'Other organization',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.35.A / R15.B
  def count_exchange_for_sex(id, reverse = false)
    map = {
      1 => '1-3',
      2 => '4-7',
      3 => '8-11',
      4 => '12 or more',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.36.1
  def exit_action(id, reverse = false)
    map = {
      0 => 'No',
      1 => 'Yes',
      9 => 'Client refused',
    }

    _translate map, id, reverse
  end

  # 4.37.1 / R17.1
  def project_completion_status(id, reverse = false)
    map = {
      1 => 'Completed project',
      2 => 'Youth voluntarily left early',
      3 => 'Youth was expelled or otherwise involuntarily discharged from project',
    }

    _translate map, id, reverse
  end

  # 4.37.A
  def early_exit_reason(id, reverse = false)
    map = {
      1 => 'Left for other opportunities - independent living',
      2 => 'Left for other opportunities - education',
      3 => 'Left for other opportunities - military',
      4 => 'Left for other opportunities - other',
      5 => 'Needs could not be met by project',
    }

    _translate map, id, reverse
  end

  # 4.37.B / R17.A
  def expelled_reason(id, reverse = false)
    map = {
      1 => 'Criminal activity/destruction of property/violence',
      2 => 'Non-compliance with project rules',
      3 => 'Non-payment of rent/occupancy charge',
      4 => 'Reached maximum time allowed by project',
      5 => 'Project terminated',
      6 => 'Unknown/disappeared',
    }

    _translate map, id, reverse
  end

  # R19.A
  def worker_response(id, reverse = false)
    map = {
      0 => 'No',
      1 => 'Yes',
      2 => 'Worker does not know',
    }

    _translate map, id, reverse
  end

  # R20.2
  def aftercare_provided(id, reverse = false)
    map = {
      0 => 'No',
      1 => 'Yes',
      9 => 'Client refused',
    }

    _translate map, id, reverse
  end

  # 4.39 / W3
  def no_assistance_reason(id, reverse = false)
    map = {
      1 => 'Applied; decision pending',
      2 => 'Applied; client not eligible',
      3 => 'Client did not apply',
      4 => 'Insurance type not applicable for this client',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.41.11 / V1.11
  def military_branch(id, reverse = false)
    map = {
      1 => 'Army',
      2 => 'Air Force',
      3 => 'Navy',
      4 => 'Marines',
      6 => 'Coast Guard',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.41.12 / V1.12
  def discharge_status(id, reverse = false)
    map = {
      1 => 'Honorable',
      2 => 'General under honorable conditions',
      4 => 'Bad conduct',
      5 => 'Dishonorable',
      6 => 'Under other than honorable conditions (OTH)',
      7 => 'Uncharacterized',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.42.1 / V4.1
  def percent_a_m_i(id, reverse = false)
    map = {
      1 => 'Less than 30%',
      2 => '30% to 50%',
      3 => 'Greater than 50%',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.43.5 / V5.5
  def address_data_quality(id, reverse = false)
    map = {
      1 => 'Full address',
      2 => 'Incomplete or estimated address',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # V6.1
  def vamcs_station_number(id, reverse = false)
    map = {
      402 => '(402) Togus, ME',
      405 => '(405) White River Junction, VT',
      436 => '(436) Montana HCS',
      437 => '(437) Fargo, ND',
      438 => '(438) Sioux Falls, SD',
      442 => '(442) Cheyenne, WY',
      459 => '(459) Honolulu, HI',
      460 => '(460) Wilmington, DE',
      463 => '(463) Anchorage, AK',
      501 => '(501) New Mexico HCS',
      502 => '(502) Alexandria, LA',
      503 => '(503) Altoona, PA',
      504 => '(504) Amarillo, TX',
      506 => '(506) Ann Arbor, MI',
      508 => '(508) Atlanta, GA',
      509 => '(509) Augusta, GA',
      512 => '(512) Baltimore HCS, MD',
      515 => '(515) Battle Creek, MI',
      516 => '(516) Bay Pines, FL',
      517 => '(517) Beckley, WV',
      518 => '(518) Bedford, MA',
      519 => '(519) Big Spring, TX',
      520 => '(520) Gulf Coast HCS, MS',
      521 => '(521) Birmingham, AL',
      523 => '(523) VA Boston HCS, MA ',
      526 => '(526) Bronx, NY',
      528 => '(528) Western New York, NY',
      529 => '(529) Butler, PA',
      531 => '(531) Boise, ID',
      534 => '(534) Charleston, SC',
      537 => '(537) Jesse Brown VAMC (Chicago), IL',
      538 => '(538) Chillicothe, OH',
      539 => '(539) Cincinnati, OH',
      540 => '(540) Clarksburg, WV',
      541 => '(541) Cleveland, OH',
      542 => '(542) Coatesville, PA',
      544 => '(544) Columbia, SC ',
      546 => '(546) Miami, FL',
      548 => '(548) West Palm Beach, FL',
      549 => '(549) Dallas, TX',
      550 => '(550) Danville, IL',
      552 => '(552) Dayton, OH',
      553 => '(553) Detroit, MI',
      554 => '(554) Denver, CO',
      556 => '(556) Captain James A Lovell FHCC',
      557 => '(557) Dublin, GA',
      558 => '(558) Durham, NC',
      561 => '(561) New Jersey HCS, NJ',
      562 => '(562) Erie, PA',
      564 => '(564) Fayetteville, AR',
      565 => '(565) Fayetteville, NC',
      568 => '(568) Black Hills HCS, SD ',
      570 => '(570) Fresno, CA',
      573 => '(573) Gainesville, FL',
      575 => '(575) Grand Junction, CO ',
      578 => '(578) Hines, IL',
      580 => '(580) Houston, TX',
      581 => '(581) Huntington, WV',
      583 => '(583) Indianapolis, IN',
      585 => '(585) Iron Mountain, MI',
      586 => '(586) Jackson, MS',
      589 => '(589) Kansas City, MO',
      590 => '(590) Hampton, VA',
      593 => '(593) Las Vegas, NV ',
      595 => '(595) Lebanon, PA',
      596 => '(596) Lexington, KY ',
      598 => '(598) Little Rock, AR ',
      600 => '(600) Long Beach, CA ',
      603 => '(603) Louisville, KY ',
      605 => '(605) Loma Linda, CA',
      607 => '(607) Madison, WI',
      608 => '(608) Manchester, NH',
      610 => '(610) Northern Indiana HCS, IN',
      612 => '(612) N. California, CA',
      613 => '(613) Martinsburg, WV',
      614 => '(614) Memphis, TN',
      618 => '(618) Minneapolis, MN',
      619 => '(619) Central Alabama Veterans HCS, AL',
      620 => '(620) VA Hudson Valley HCS, NY',
      621 => '(621) Mountain Home, TN',
      623 => '(623) Muskogee, OK',
      626 => '(626) Middle Tennessee HCS, TN',
      629 => '(629) New Orleans, LA',
      630 => '(630) New York Harbor HCS, NY',
      631 => '(631) VA Central Western Massachusetts HCS',
      632 => '(632) Northport, NY',
      635 => '(635) Oklahoma City, OK',
      636 => '(636) Nebraska-W Iowa, NE',
      637 => '(637) Asheville, NC',
      640 => '(640) Palo Alto, CA ',
      642 => '(642) Philadelphia, PA ',
      644 => '(644) Phoenix, AZ',
      646 => '(646) Pittsburgh, PA',
      648 => '(648) Portland, OR',
      649 => '(649) Northern Arizona HCS',
      650 => '(650) Providence, RI',
      652 => '(652) Richmond, VA',
      653 => '(653) Roseburg, OR',
      654 => '(654) Reno, NV',
      655 => '(655) Saginaw, MI',
      656 => '(656) St. Cloud, MN',
      657 => '(657) St. Louis, MO',
      658 => '(658) Salem, VA',
      659 => '(659) Salisbury, NC',
      660 => '(660) Salt Lake City, UT',
      662 => '(662) San Francisco, CA',
      663 => '(663) VA Puget Sound, WA',
      664 => '(664) San Diego, CA',
      666 => '(666) Sheridan, WY',
      667 => '(667) Shreveport, LA',
      668 => '(668) Spokane, WA',
      671 => '(671) San Antonio, TX',
      672 => '(672) San Juan, PR',
      673 => '(673) Tampa, FL',
      674 => '(674) Temple, TX',
      675 => '(675) Orlando, FL',
      676 => '(676) Tomah, WI',
      678 => '(678) Southern Arizona HCS',
      679 => '(679) Tuscaloosa, AL',
      687 => '(687) Walla Walla, WA',
      688 => '(688) Washington, DC',
      689 => '(689) VA Connecticut HCS, CT',
      691 => '(691) Greater Los Angeles HCS',
      692 => '(692) White City, OR',
      693 => '(693) Wilkes-Barre, PA',
      695 => '(695) Milwaukee, WI',
      740 => '(740) VA Texas Valley Coastal Bend HCS',
      756 => '(756) El Paso, TX',
      757 => '(757) Columbus, OH',
      '459GE' => '(459GE) Guam',
      '528A5' => '(528A5) Canandaigua, NY',
      '528A6' => '(528A6) Bath, NY',
      '528A7' => '(528A7) Syracuse, NY',
      '528A8' => '(528A8) Albany, NY',
      '589A4' => '(589A4) Columbia, MO',
      '589A5' => '(589A5) Kansas City, MO',
      '589A6' => '(589A6) Eastern KS HCS, KS',
      '589A7' => '(589A7) Wichita, KS',
      '636A6' => '(636A6) Central Iowa, IA ',
      '636A8' => '(636A8) Iowa City, IA',
      '657A4' => '(657A4) Poplar Bluff, MO',
      '657A5' => '(657A5) Marion, IL',
      99 => 'not collected',
    }

    _translate map, id, reverse
  end

  # 4.47.B / W4.B
  def t_cell_source_viral_load_source(id, reverse = false)
    map = {
      1 => 'Medical Report',
      2 => 'Client Report',
      3 => 'Other',
    }

    _translate map, id, reverse
  end

  # 4.47.3 / W4.3
  def viral_load_available(id, reverse = false)
    map = {
      0 => 'Not available',
      1 => 'Available',
      2 => 'Undetectable',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.48.1 / V7.1
  def no_points_yes(id, reverse = false)
    map = {
      0 => 'No (0 points)',
      1 => 'Yes',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.48.2 / V7.2 / V7.A TimeToHousingLoss
  def time_to_housing_loss(id, reverse = false)
    map = {
      0 => '1-6 days',
      1 => '7-13 days',
      2 => '14-21 days',
      3 => 'More than 21 days',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.48.4 / V7.4 / V7.B AnnualPercentAMI
  def annual_percent_a_m_i(id, reverse = false)
    map = {
      0 => '$0 (i.e., not employed, not receiving cash benefits, no other current income)',
      1 => '1-14% of Area Median Income (AMI) for household size',
      2 => '15-30% of AMI for household size',
      3 => 'More than 30% of AMI for household size',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.48.7 / V7.7 / V7.G EvictionHistory
  def eviction_history(id, reverse = false)
    map = {
      0 => 'No prior rental evictions',
      1 => '1 prior rental eviction',
      2 => '2 or more prior rental evictions',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.48.9 / V7.9 / V7.C LiteralHomelessHistory
  def literal_homeless_history(id, reverse = false)
    map = {
      0 => 'Most recent episode occurred in the last year',
      1 => 'Most recent episode occurred more than one year ago',
      2 => 'None',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # V7.I IncarceratedAdult
  def incarcerated_adult
    map = {
      0 => 'Not incarcerated',
      1 => 'Incarcerated once',
      2 => 'Incarcerated two or more times',
      99 => 'Data not collected',
    }
    _translate map, id, reverse
  end

  # V7.O DependentUnder6
  def dependent_under_6
    map = {
      0 => 'No',
      1 => 'Youngest child is under 1 year old',
      2 => 'Youngest child is 1 to 6 years old and/or one or more children (any age) require significant care',
      99 => 'Data not collected',
    }
    _translate map, id, reverse
  end

  # V8.1
  def voucher_tracking(id, reverse = false)
    map = {
      1 => 'Referral package forwarded to PHA',
      2 => 'Voucher denied by PHA',
      3 => 'Voucher issued by PHA',
      4 => 'Voucher revoked or expired',
      5 => 'Voucher in use - veteran moved into housing',
      6 => 'Voucher was ported locally',
      7 => 'Voucher was administratively absorbed by new PHA',
      8 => 'Voucher was converted to Housing Choice Voucher',
      9 => 'Veteran exited - voucher was returned',
      10 => 'Veteran exited - family maintained the voucher',
      11 => 'Veteran exited - prior to ever receiving a voucher',
      12 => 'Other',
    }

    _translate map, id, reverse
  end

  # V9.1
  def cm_exit_reason(id, reverse = false)
    map = {
      1 => 'Accomplished goals and/or obtained services and no longer needs CM',
      2 => 'Transferred to another HUD/VASH program site',
      3 => 'Found/chose other housing',
      4 => 'Did not comply with HUD/VASH CM',
      5 => 'Eviction and/or other housing related issues',
      6 => 'Unhappy with HUD/VASH housing',
      7 => 'No longer financially eligible for HUD/VASH voucher',
      8 => 'No longer interested in participating in this program',
      9 => 'Veteran cannot be located',
      10 => 'Veteran too ill to participate at this time',
      11 => 'Veteran is incarcerated',
      12 => 'Veteran is deceased',
      13 => 'Other',
    }

    _translate map, id, reverse
  end

  # 4.49.1
  def crisis_services_use(id, reverse = false)
    map = {
      0 => '0',
      1 => '1-2',
      2 => '3-5',
      3 => '6-10',
      4 => '11-20',
      5 => 'More than 20',
      8 => 'Client doesn\'t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 5.03.1
  def data_collection_stage(id, reverse = false)
    map = data_collection_stages

    _translate map, id, reverse
  end

  # C1.1 WellbeingAgreement
  def wellbeing_agreement
    map = {
      0 => 'Strongly disagree',
      1 => 'Somewhat disagree',
      2 => 'Neither agree nor disagree',
      3 => 'Somewhat agree',
      4 => 'Strongly agree',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }
    _translate map, id, reverse
  end

  # C1.2 FeelingFrequency
  def feeling_frequency
    map = {
      0 => 'Not at all',
      1 => 'Once a month',
      2 => 'Several times a month',
      3 => 'Several times a week',
      4 => 'At least every day',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }
    _translate map, id, reverse
  end

  # C2.2 MovingOnAssistance
  def moving_on_assistance
    map = {
      1 => 'Subsidized housing application assistance',
      2 => 'Financial assistance for Moving On (e.g., security deposit, moving expenses)',
      3 => 'Non-financial assistance for Moving On (e.g., housing navigation, transition support)',
      4 => 'Housing referral/placement',
      5 => 'Other (please specify)',
    }
    _translate map, id, reverse
  end

  # C3.2 CurrentSchoolAttend
  def current_school_attended
    map = {
      0 => 'Not currently enrolled in any school or educational course',
      1 => 'Currently enrolled but NOT attending regularly (when school or the course is in session)',
      2 => 'Currently enrolled and attending regularly (when school or the course is in session)',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }
    _translate map, id, reverse
  end

  # C3.A MostRecentEdStatus
  def most_recent_ed_status
    map = {
      0 => 'K12: Graduated from high school',
      1 => 'K12: Obtained GED',
      2 => 'K12: Dropped out',
      3 => 'K12: Suspended',
      4 => 'K12: Expelled',
      5 => 'Higher education: Pursuing a credential but not currently attending',
      6 => 'Higher education: Dropped out',
      7 => 'Higher education: Obtained a credential/degree',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }
    _translate map, id, reverse
  end

  # C3.B CurrentEdStatus
  def current_ed_status
    map = {
      0 => 'Pursuing a high school diploma or GED',
      1 => 'Pursuing Associate’s Degree',
      2 => 'Pursuing Bachelor’s Degree',
      3 => 'Pursuing Graduate Degree',
      4 => 'Pursuing other post-secondary credential',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }
    _translate map, id, reverse
  end

  def data_collection_stages
    {
      1 => 'Project entry',
      2 => 'Update',
      3 => 'Project exit',
      5 => 'Annual assessment',
      6 => 'Post-exit', # not used in CSV
    }.freeze
  end

  def coc_name(coc_code)
    cocs.try(:[], coc_code) || coc_code
  end

  def valid_coc?(coc_code)
    cocs.key?(coc_code)
  end

  def cocs
    {
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
    }.freeze
  end
end
