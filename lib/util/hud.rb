# a general clearing house to translate HUD ids of various sorts into strings
# further access or translation logic can also go here
# information from HMIS CSV format specifications version 5
module HUD

  module_function

  # factored out of app/models/grda_warehouse/tasks/identify_duplicates.rb
  def valid_social? ssn
    # see https://en.wikipedia.org/wiki/Social_Security_number#Structure
    if ssn.blank? || ssn.length != 9
      return false
    else
      area_number = ssn.first(3)
      group_number = ssn[3..4]
      serial_number = ssn.last(4)

      if area_number.to_i == 0 || group_number.to_i == 0 || serial_number.to_i == 0
        return false
      elsif area_number.to_i >= 900 || area_number == '666'
        return false
      elsif ['219099999', '078051120', '123456789'].include?(ssn)
        return false
      elsif ssn.split('').uniq.count == 1 #all the same number
        return false
      end
    end
    return true
  end

  # for fuzzy translation from strings back to their controlled vocabular key
  def forgiving_regex(str)
    Regexp.new '^' + str.strip.gsub( /\W+/, '\W+' ) + '$', 'i'
  end

  def _translate(map, id, reverse)
    if reverse
      rx = forgiving_regex id
      map.detect{ |_,v| rx === v }.try(&:first)
    else
      map[id] || id
    end
  end

  def race(field, reverse=false)
    map = races
    _translate map, field, reverse
  end

  def races
    {
      'AmIndAKNative' => 'American Indian or Alaska Native',
      'Asian' => 'Asian',
      'BlackAfAmerican' => 'Black or African American',
      'NativeHIOtherPacific' => 'Native Hawaiian or Other Pacific Islander',
      'White' => 'White',
      'RaceNone' => 'none',
    }
  end

  # for translating straight from a controlled vocabulary list identifier and integer
  # to the corresponding phrase
  def list(number, id, reverse=false)
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
    when '4.4.A' then :reason_not_insured
    when '4.9.D' then :p_a_t_h_how_confirmed
    when '4.9.E' then :p_a_t_h_s_m_i_information
    when '4.10.2' then :disability_response
    when '4.11.A' then :when_d_v_occurred
    when '4.12.2' then :contact_location
    when '4.14.A' then :p_a_t_h_services
    when '4.14.B' then :r_h_y_services
    when '4.14.C' then :h_o_p_w_a_services
    when '4.14.D' then :s_s_v_f_services
    when '4.14.D3' then :s_s_v_f_sub_type3
    when '4.14.D4' then :s_s_v_f_sub_type4
    when '4.14.D5' then :s_s_v_f_sub_type5
    when '4.15.A' then :h_o_p_w_a_financial_assistance
    when '4.14E' then :bed_night
    when '4.15.B' then :s_s_v_f_financial_assistance
    when '4.16.A' then :p_a_t_h_referral
    when '4.16.B' then :r_h_y_referral
    when '4.16.A1' then :p_a_t_h_referral_outcome
    when '4.18.1' then :housing_assessment_disposition
    when '4.19.1' then :housing_assessment_at_exit
    when '4.19.A' then :subsidy_information
    when '4.20.A' then :reason_not_enrolled
    when '4.22.A' then :reason_no_services
    when '4.23.1' then :sexual_orientation
    when '4.24.1' then :last_grade_completed
    when '4.25.1' then :school_status
    when '4.26.A' then :employment_type
    when '4.26.B' then :not_employed_reason
    when '4.27.1' then :health_status
    when '4.31.A' then :r_h_y_numberof_years
    when '4.33.A' then :incarcerated_parent_status
    when '4.34.1' then :referral_source
    when '4.35.A' then :count_exchange_for_sex
    when '4.36.1' then :exit_action
    when '4.37.1' then :project_completion_status
    when '4.37.A' then :early_exit_reason
    when '4.37.B' then :expelled_reason
    when '4.39' then :no_assistance_reason
    when '4.41.11' then :military_branch
    when '4.41.12' then :discharge_status
    when '4.42.1' then :percent_a_m_i
    when '4.43.5' then :address_data_quality
    when '4.47.B' then :t_cell_source_viral_load_source
    when '4.47.3' then :viral_load_available
    when '4.48.1' then :no_points_yes
    when '4.48.2' then :time_to_housing_loss
    when '4.48.4' then :annual_percent_a_m_i
    when '4.48.7' then :eviction_history
    when '4.48.9' then :literal_homeless_history
    when '4.49.1' then :crisis_services_use
    when '5.3.1' then :data_collection_stage
    when 'ad_hoc_yes_no_1' then :ad_hoc_yes_no_1
    else
      raise "unknown controlled vocabulary list: #{number}"
    end
    send method, id, reverse
  end

  # 1.1
  def export_period_type(id, reverse=false)
    map = {
      1 => 'Updated',
      2 => 'Effective',
      3 => 'Reporting period',
      4 => 'Other',
    }

    _translate map, id, reverse
  end

  #1.2
  def export_directive(id, reverse=false)
    map = {
      1 => 'Delta refresh',
      2 => 'Full refresh',
      3 => 'Other',
    }

    _translate map, id, reverse
  end

  # 1.3
  def disability_type(id, reverse=false)
    map = disability_types
    _translate map, id, reverse
  end

  def disability_types
    {
      5 => 'Physical disability',
      6 => 'Developmental disability',
      7 => 'Chronic health condition',
      8 => 'HIV/AIDS',
      9 => 'Mental health problem',
      10 => 'Substance abuse',
    }
  end

  # 1.4
  def record_type(id, reverse=false)
    map = {
      12 => 'Contact',
      141 => 'PATH service',
      142 => 'RHY service',
      143 => 'HOPWA service',
      144 => 'SSVF service',
      151 => 'HOPWA financial assistance',
      152 => 'SSVF financial assistance',
      161 => 'PATH referral',
      162 => 'RHY referral',
      200 => 'Bed night',
    }

    _translate map, id, reverse
  end

  # 1.5
  def hash_status(id, reverse=false)
    map = {
      1 => 'Unhashed',
      2 => 'SHA-1 RHY',
      3 => 'Hashed - other',
      4 => 'SHA-256 (RHY)',
    }

    _translate map, id, reverse
  end

  # 1.6
  def race_none(id, reverse=false)
    map = {
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 1.7
  def no_yes_missing(id, reverse=false)
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

  def ad_hoc_yes_no_1(id, reverse=false)
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
  def no_yes_reasons_for_missing_data(id, reverse=false)
    map = no_yes_reasons_for_missing_data_options

    _translate map, id, reverse
  end

  def no_yes_reasons_for_missing_data_options
    {
      0 => 'No',
      1 => 'Yes',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }
  end

  def veteran_status(*args)
    no_yes_reasons_for_missing_data *args
  end

  # 1.9
  def source_type(id, reverse=false)
    map = {
      1 => 'CoC HMIS',
      2 => 'Standalone/agency-specific application',
      3 => 'Data warehouse',
      4 => 'Other',
    }

    _translate map, id, reverse
  end

  # 2.4.2
  def project_type(id, reverse=false, translate=true)
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
      9 => 'PH – Housing Only',
      10 => 'PH – Housing with Services (no disability required for entry)',
      11 => 'Day Shelter',
      12 => 'Homelessness Prevention',
      13 => 'PH - Rapid Re-Housing',
      14 => 'Coordinated Assessment',
    }
  end

  def project_type_brief id
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
      'PH'
    when 14
      'Coordinated Assessment'
    end
  end

  # 2.5.1
  def tracking_method(id, reverse=false)
    map = {
      0 => 'Entry/Exit Date',
      3 => 'Night-by-Night',
      nil => 'Entry/Exit Date',
    }

    _translate map, id, reverse
  end

  # 2.6.1
  def funding_source(id, reverse=false)
    map = {
      1 => 'HUD: CoC – Homelessness Prevention (High Performing Comm. Only)',
      2 => 'HUD: CoC – Permanent Supportive Housing',
      3 => 'HUD: CoC – Rapid Re-Housing',
      4 => 'HUD: CoC – Supportive Services Only',
      5 => 'HUD: CoC – Transitional Housing',
      6 => 'HUD: CoC – Safe Haven',
      7 => 'HUD: CoC – Single Room Occupancy (SRO)',
      8 => 'HUD: ESG – Emergency Shelter (operating and/or essential services)',
      9 => 'HUD: ESG – Homelessness Prevention',
      10 => 'HUD: ESG – Rapid Rehousing',
      11 => 'HUD: ESG – Street Outreach',
      12 => 'HUD: Rural Housing Stability Assistance Program',
      13 => 'HUD: HOPWA – Hotel/Motel Vouchers',
      14 => 'HUD: HOPWA – Housing Information',
      15 => 'HUD: HOPWA – Permanent Housing (facility based or TBRA)',
      16 => 'HUD: HOPWA – Permanent Housing Placement',
      17 => 'HUD: HOPWA – Short-Term Rent, Mortgage, Utility assistance',
      18 => 'HUD: HOPWA – Short-Term Supportive Facility',
      19 => 'HUD: HOPWA – Transitional Housing (facility based or TBRA)',
      20 => 'HUD: HUD/VASH',
      21 => 'HHS: PATH – Street Outreach & Supportive Services Only',
      22 => 'HHS: RHY – Basic Center Program (prevention and shelter)',
      23 => 'HHS: RHY – Maternity Group Home for Pregnant and Parenting Youth',
      24 => 'HHS: RHY – Transitional Living Program',
      25 => 'HHS: RHY – Street Outreach Project',
      26 => 'HHS: RHY – Demonstration Project**',
      27 => 'VA: Community Contract Emergency Housing',
      28 => 'VA: Community Contract Residential Treatment Program***',
      29 => 'VA: Domiciliary Care***',
      30 => 'VA: Community Contract Safe Haven Program***',
      31 => 'VA: Grant and Per Diem Program',
      32 => 'VA: Compensated Work Therapy Transitional Residence***',
      33 => 'VA: Supportive Services for Veteran Families',
      34 => 'N/A',
    }

    _translate map, id, reverse
  end

  # 2.7.2
  def household_type(id, reverse=false)
    map = {
      1 => 'Households without children',
      3 => 'Households with at least one adult and one child',
      4 => 'Households with only children',
    }

    _translate map, id, reverse
  end

  # 2.7.3
  def bed_type(id, reverse=false)
    map = {
      1 => 'Facility-based',
      2 => 'Voucher',
      3 => 'Other',
    }

    _translate map, id, reverse
  end

  # 2.7.4
  def availability(id, reverse=false)
    map = {
      1 => 'Year-round',
      2 => 'Seasonal',
      3 => 'Overflow',
    }

    _translate map, id, reverse
  end

  # 2.7.B
  def youth_age_group(id, reverse=false)
    map = {
      1 => 'Only under age 18',
      2 => 'Only ages 18 to 24',
      3 => 'Only youth under age 24 (both of the above)',
    }

    _translate map, id, reverse
  end

  # 2.8.7
  def geography_type(id, reverse=false)
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

  # 2.8.8
  def housing_type(id, reverse=false)
    map = housing_types

    _translate map, id, reverse
  end

  def housing_types
    {
      1 => 'Site-based – single site',
      2 => 'Site-based – clustered / multiple sites',
      3 => 'Tenant-based - scattered site',
    }
  end

  # 2.9.1
  def target_population(id, reverse=false)
    map = {
      1 => 'Domestic violence victims',
      3 => 'Persons with HIV/AIDS',
      4 => 'Not applicable',
    }

    _translate map, id, reverse
  end

  # 3.1.5
  def name_data_quality(id, reverse=false)
    map = {
      1 => 'Full name reported',
      2 => 'Partial, street name, or code name reported',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 3.2.2
  def ssn_data_quality(id, reverse=false)
    map = {
      1 => 'Full SSN reported',
      2 => 'Approximate or partial SSN reported',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 3.3.2
  def dob_data_quality(id, reverse=false)
    map = {
      1 => 'Full DOB reported',
      2 => 'Approximate or partial DOB reported',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 3.5.1
  def ethnicity(id, reverse=false)
    map = ethnicities

    _translate map, id, reverse
  end

  def ethnicities
    {
      0 => 'Non-Hispanic/Non-Latino',
      1 => 'Hispanic/Latino',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }
  end

  # 3.6.1
  def gender(id, reverse=false)
    map = genders
    _translate map, id, reverse
  end

  def genders
    {
      0 => 'Female',
      1 => 'Male',
      2 => 'Trans Female (MTF or Male to Female)',
      3 => 'Trans Male (FTM or Female to Male)',
      4 => 'Gender non-conforming (i.e. not exclusively male or female)',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }
  end

  # 3.917.1
  def living_situation(id, reverse=false)
    map = living_situations
    _translate map, id, reverse
  end

  def living_situations
    {
      1 => 'Emergency shelter, including hotel or motel paid for with emergency shelter voucher',
      2 => 'Transitional housing for homeless persons',
      3 => 'Permanent housing for formerly homeless persons',
      4 => 'Psychiatric hospital or other psychiatric facility',
      5 => 'Substance abuse treatment facility or detox center',
      6 => 'Hospital or other residential non-psychiatric medical facility',
      7 => 'Jail, prison or juvenile detention facility',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      12 => 'Staying or living in a family member’s room, apartment or house',
      13 => 'Staying or living in a friend’s room, apartment or house',
      14 => 'Hotel or motel paid for without emergency shelter voucher',
      15 => 'Foster care home or foster care group home',
      16 => 'Place not meant for habitation',
      17 => 'Other',
      18 => 'Safe Haven',
      19 => 'Rental by client, with VASH subsidy',
      20 => 'Rental by client, with other ongoing housing subsidy',
      21 => 'Owned by client, with ongoing housing subsidy',
      22 => 'Rental by client, no ongoing housing subsidy',
      23 => 'Owned by client, no ongoing housing subsidy',
      24 => 'Long-term care facility or nursing home',
      25 => 'Rental by client, with GPD TIP subsidy',
      26 => 'Residential project or halfway house with no homeless criteria',
      27 => 'Interim housing',
      99 => 'Data not collected',
    }
  end

  # 3.917.2
  def residence_prior_length_of_stay(id, reverse=false)
    map = {
      2 => 'One week or more, but less than one month',
      3 => 'One month or more, but less than 90 days',
      4 => '90 days or more but less than one year',
      5 => 'One year or longer',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      10 => 'One night or less',
      11 => 'Two to six nights',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end
  def residence_prior_length_of_stay_brief(id, reverse=false)
    map = {
      2 => '7-30',
      3 => '30-90',
      4 => '90-365',
      5 => '365+',
      8 => '',
      9 => '',
      10 => '0-7',
      11 => '0-7',
      99 => '',
    }

    _translate map, id, reverse
  end


  # 3.917.4
  def times_homeless_past_three_years(id, reverse=false)
    map = {
      1 => 'One time',
      2 => 'Two times',
      3 => 'Three times',
      4 => 'Four or more times',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end
  def times_homeless_past_three_years_brief(id, reverse=false)
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
  def months_homeless_past_three_years(id, reverse=false)
    map = {
      8 => 'Client doesn’t know',
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

    _translate map, id, reverse
  end
  def months_homeless_past_three_years_brief(id, reverse=false)
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

  # 3.12.1
  def destination(id, reverse=false)
    map = valid_destinations()

    _translate map, id, reverse
  end

  def valid_destinations()
    {
      1 => 'Emergency shelter, including hotel or motel paid for with emergency shelter voucher',
      2 => 'Transitional housing for homeless persons (including homeless youth)',
      3 => 'Permanent housing for formerly homeless persons (such as: CoC project; or HUD legacy programs; or HOPWA PH)',
      4 => 'Psychiatric hospital or other psychiatric facility',
      5 => 'Substance abuse treatment facility or detox center',
      6 => 'Hospital or other residential non-psychiatric medical facility',
      7 => 'Jail, prison or juvenile detention facility',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      10 => 'Rental by client, no ongoing housing subsidy',
      11 => 'Owned by client, no ongoing housing subsidy',
      12 => 'Staying or living with family, temporary tenure (e.g., room, apartment or house)',
      13 => 'Staying or living with friends, temporary tenure (e.g., room apartment or house)',
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
      99 => 'Data not collected',
    }
  end

  def permanent_destinations()
    # Permanent destinations
    {
      3 => 'Permanent housing for formerly homeless persons (such as: CoC project; or HUD legacy programs; or HOPWA PH)',
      10 => 'Rental by client, no ongoing housing subsidy',
      11 => 'Owned by client, no ongoing housing subsidy',
      19 => 'Rental by client, with VASH housing subsidy',
      20 => 'Rental by client, with other ongoing housing subsidy',
      21 => 'Owned by client, with ongoing housing subsidy',
      22 => 'Staying or living with family, permanent tenure',
      23 => 'Staying or living with friends, permanent tenure',
      24 => 'Deceased',
      26 => 'Moved from one HOPWA funded project to HOPWA PH',
      28 => 'Rental by client, with GPD TIP housing subsidy',
      31 => 'Rental by client, with RRH or equivalent subsidy',
    }.keys
  end

  def temporary_destinations()
    # Temporary destinations
    {
      1 => 'Emergency shelter, including hotel or motel paid for with emergency shelter voucher',
      2 => 'Transitional housing for homeless persons (including homeless youth)',
      12 => 'Staying or living with family, temporary tenure (e.g., room, apartment or house)',
      13 => 'Staying or living with friends, temporary tenure (e.g., room apartment or house)',
      14 => 'Hotel or motel paid for without emergency shelter voucher',
      16 => 'Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)',
      18 => 'Safe Haven',
      27 => 'Moved from one HOPWA funded project to HOPWA TH',
    }.keys
  end
  def institutional_destinations()
    # Institutional Destinations
    {
      4 => 'Psychiatric hospital or other psychiatric facility',
      5 => 'Substance abuse treatment facility or detox center',
      6 => 'Hospital or other residential non-psychiatric medical facility',
      7 => 'Jail, prison or juvenile detention facility',
      15 => 'Foster care home or foster care group home',
      25 => 'Long-term care facility or nursing home',
      29 => 'Residential project or halfway house with no homeless criteria',
    }.keys
  end
  def other_destinations()
    {
      # Other Destinations
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      17 => 'Other',
      30 => 'No exit interview completed',
      99 => 'Data not collected',
    }.keys
  end

  # 3.15.1
  def relationship_to_hoh(id, reverse=false)
    map = {
      1 => 'Self (head of household)',
      2 => 'Child',
      3 => 'Spouse or partner',
      4 => 'Other relative',
      5 => 'Unrelated household member',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.1.1
  def housing_status(id, reverse=false)
    map = {
      1 => 'Category 1 - Homeless',
      2 => 'Category 2 - At imminent risk of losing housing',
      3 => 'At-risk of homelessness',
      4 => 'Stably housed',
      5 => 'Category 3 - Homeless only under other federal statutes',
      6 => 'Category 4 - Fleeing domestic violence',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.4.A
  def reason_not_insured(id, reverse=false)
    map = {
      1 => 'Applied; decision pending',
      2 => 'Applied; client not eligible',
      3 => 'Client did not apply',
      4 => 'Insurance type n/a for this client',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.9.D
  def p_a_t_h_how_confirmed(id, reverse=false)
    map = {
      1 => 'Unconfirmed; presumptive or self-report',
      2 => 'Confirmed through assessment and clinical evaluation',
      3 => 'Confirmed by prior evaluation or clinical records',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.9.E
  def p_a_t_h_s_m_i_information(id, reverse=false)
    map = {
      0 => 'No',
      1 => 'Unconfirmed; presumptive or self-report',
      2 => 'Confirmed through assessment and clinical evaluation',
      3 => 'Confirmed by prior evaluation or clinical records',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.10.2
  def disability_response(id, reverse=false)
    map = {
      0 => 'No',
      1 => 'Alcohol abuse',
      2 => 'Drug abuse',
      3 => 'Both alcohol and drug abuse',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.11.A
  def when_d_v_occurred(id, reverse=false)
    map = {
      1 => 'Within the past three months',
      2 => 'Three to six months ago (excluding six months exactly)',
      3 => 'Six months to one year ago (excluding one year exactly)',
      4 => 'One year or more',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.12.2
  def contact_location(id, reverse=false)
    map = {
      1 => 'Place not meant for habitation',
      2 => 'Service setting, non-residential',
      3 => 'Service setting, residential',
    }

    _translate map, id, reverse
  end

  # 4.14.A
  def p_a_t_h_services(id, reverse=false)
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

  # 4.14.B
  def r_h_y_services(id, reverse=false)
    map = {
      1 => 'Basic support services',
      2 => 'Community service/service learning (CSL)',
      3 => 'Counseling/therapy',
      4 => 'Dental care',
      5 => 'Education',
      6 => 'Employment and training services',
      7 => 'Criminal justice /legal services',
      8 => 'Life skills training',
      9 => 'Parenting education for parent of youth',
      10 => 'Parenting education for youth with children',
      11 => 'Peer (youth) counseling',
      12 => 'Post-natal care',
      13 => 'Pre-natal care',
      14 => 'Health/medical care',
      15 => 'Psychological or psychiatric care',
      16 => 'Recreational activities',
      17 => 'Substance abuse assessment and/or treatment',
      18 => 'Substance abuse prevention',
      19 => 'Support group',
      20 => 'Preventative – overnight interim, respite',
      21 => 'Preventative – formal placement in an alternative setting outside of BCP',
      22 => 'Preventative – entry into BCP after preventative services',
      23 => 'Street outreach – health and hygiene products distributed',
      24 => 'Street outreach – food and drink items',
      25 => 'Street outreach – services information/brochures',
    }

    _translate map, id, reverse
  end

  # 4.14.C
  def h_o_p_w_a_services(id, reverse=false)
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

  # 4.14.D
  def s_s_v_f_services(id, reverse=false)
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

  # 4.14.D3
  def s_s_v_f_sub_type3(id, reverse=false)
    map = {
      1 => 'VA vocational and rehabilitation counseling',
      2 => 'Employment and training services',
      3 => 'Educational assistance',
      4 => 'Health care services',
    }

    _translate map, id, reverse
  end

  # 4.14.D4
  def s_s_v_f_sub_type4(id, reverse=false)
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
      10 => 'Legal services - restore / acquire driver’s license',
      11 => 'Legal services - other',
      12 => 'Child care',
      13 => 'Housing counseling',
    }

    _translate map, id, reverse
  end

  # 4.14.D5
  def s_s_v_f_sub_type5(id, reverse=false)
    map = {
      1 => 'Personal financial planning services',
      2 => 'Transportation services',
      3 => 'Income support services',
      4 => 'Fiduciary and representative payee services',
      5 => 'Legal services - child support',
      6 => 'Legal services - eviction prevention',
      7 => 'Legal services - outstanding fines and penalties',
      8 => 'Legal services - restore / acquire driver’s license',
      9 => 'Legal services - other',
      10 => 'Child care',
      11 => 'Housing counseling',
    }

    _translate map, id, reverse
  end

  # 4.15.A
  def h_o_p_w_a_financial_assistance(id, reverse=false)
    map = {
      1 => 'Rental assistance',
      2 => 'Security deposits',
      3 => 'Utility deposits',
      4 => 'Utility payments',
      7 => 'Mortgage assistance',
    }

    _translate map, id, reverse
  end

  # 4.14E
  def bed_night(id, reverse=false)
    map = {
      200 => 'BedNight',
    }

    _translate map, id, reverse
  end

  # 4.15.B
  def s_s_v_f_financial_assistance(id, reverse=false)
    map = {
      1 => 'Rental assistance',
      2 => 'Security deposit',
      3 => 'Utility deposit',
      4 => 'Utility fee payment assistance',
      5 => 'Moving costs',
      8 => 'Transportation services: tokens/vouchers',
      9 => 'Transportation services: vehicle repair/maintenance',
      10 => 'Child care',
      11 => 'General housing stability assistance - emergency supplies',
      12 => 'General housing stability assistance - other',
      14 => 'Emergency housing assistance',
    }

    _translate map, id, reverse
  end

  # 4.16.A
  def p_a_t_h_referral(id, reverse=false)
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
  def r_h_y_referral(id, reverse=false)
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

  # 4.16.A1
  def p_a_t_h_referral_outcome(id, reverse=false)
    map = {
      1 => 'Attained',
      2 => 'Not attained',
      3 => 'Unknown',
    }

    _translate map, id, reverse
  end

  # 4.18.1
  def housing_assessment_disposition(id, reverse=false)
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

  # 4.19.1
  def housing_assessment_at_exit(id, reverse=false)
    map = {
      1 => 'Able to maintain the housing they had at project entry',
      2 => 'Moved to new housing unit',
      3 => 'Moved in with family/friends on a temporary basis',
      4 => 'Moved in with family/friends on a permanent basis',
      5 => 'Moved to a transitional or temporary housing facility or program',
      6 => 'Client became homeless – moving to a shelter or other place unfit for human habitation',
      7 => 'Client went to jail/prison',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      10 => 'Client died',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.19.A
  def subsidy_information(id, reverse=false)
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

  # 4.20.A
  def reason_not_enrolled(id, reverse=false)
    map = {
      1 => 'Client was found ineligible for PATH',
      2 => 'Client was not enrolled for other reason(s)',
    }

    _translate map, id, reverse
  end

  # 4.22.A
  def reason_no_services(id, reverse=false)
    map = {
      1 => 'Out of age range',
      2 => 'Ward of the state',
      3 => 'Ward of the criminal justice system',
      4 => 'Other',
    }

    _translate map, id, reverse
  end

  # 4.23.1
  def sexual_orientation(id, reverse=false)
    map = {
      1 => 'Heterosexual',
      2 => 'Gay',
      3 => 'Lesbian',
      4 => 'Bisexual',
      5 => 'Questioning / unsure',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.24.1
  def last_grade_completed(id, reverse=false)
    map = {
      1 => 'Less than grade 5',
      2 => 'Grades 5-6',
      3 => 'Grades 7-8',
      4 => 'Grades 9-11',
      5 => 'Grade 12',
      6 => 'School program does not have grade levels',
      7 => 'GED',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      10 => 'Some college',
      11 => 'Associate’s degree',
      12 => 'Bachelor’s degree',
      13 => 'Graduate degree',
      14 => 'Vocational certification',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.25.1
  def school_status(id, reverse=false)
    map = {
      1 => 'Attending school regularly',
      2 => 'Attending school irregularly',
      3 => 'Graduated from high school',
      4 => 'Obtained GED',
      5 => 'Dropped out',
      6 => 'Suspended',
      7 => 'Expelled',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.26.A
  def employment_type(id, reverse=false)
    map = {
      1 => 'Full-time',
      2 => 'Part-time',
      3 => 'Seasonal / sporadic (including day labor)',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.26.B
  def not_employed_reason(id, reverse=false)
    map = {
      1 => 'Looking for work',
      2 => 'Unable to work',
      3 => 'Not looking for work',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.27.1
  def health_status(id, reverse=false)
    map = {
      1 => 'Excellent',
      2 => 'Very good',
      3 => 'Good',
      4 => 'Fair',
      5 => 'Poor',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.31.A
  def r_h_y_numberof_years(id, reverse=false)
    map = {
      1 => 'Less than one year',
      2 => '1 to 2 years',
      3 => '3 to 5 or more years',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.33.A
  def incarcerated_parent_status(id, reverse=false)
    map = {
      1 => 'One parent / legal guardian is incarcerated',
      2 => 'Both parents / legal guardians are incarcerated',
      3 => 'The only parent / legal guardian is incarcerated',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.34.1
  def referral_source(id, reverse=false)
    map = {
      1 => 'Self-referral',
      2 => 'Individual: parent/guardian',
      3 => 'Individual: relative or friend',
      4 => 'Individual: other adult or youth',
      5 => 'Individual: partner/spouse',
      6 => 'Individual: foster parent',
      7 => 'Outreach project: FYSB',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      10 => 'Outreach project: other',
      11 => 'Temporary shelter: FYSB basic center project',
      12 => 'Temporary shelter: other youth only emergency shelter',
      13 => 'Temporary shelter: emergency shelter for families',
      14 => 'Temporary shelter: emergency shelter for individuals',
      15 => 'Temporary shelter: domestic violence shelter',
      16 => 'Temporary shelter: safe place',
      17 => 'Temporary shelter: other',
      18 => 'Residential project: FYSB transitional living project',
      19 => 'Residential project: other transitional living project',
      20 => 'Residential project: group home',
      21 => 'Residential project: independent living project',
      22 => 'Residential project: job corps',
      23 => 'Residential project: drug treatment center',
      24 => 'Residential project: treatment center',
      25 => 'Residential project: educational institute',
      26 => 'Residential project: other agency project',
      27 => 'Residential project: other project',
      28 => 'Hotline: national runaway switchboard',
      29 => 'Hotline: other',
      30 => 'Other agency: child welfare/CPS',
      31 => 'Other agency: non-residential independent living project',
      32 => 'Other project operated by your agency',
      33 => 'Other youth services agency',
      34 => 'Juvenile justice',
      35 => 'Law enforcement/ police',
      36 => 'Religious organization',
      37 => 'Mental hospital',
      38 => 'School',
      39 => 'Other organization',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.35.A
  def count_exchange_for_sex(id, reverse=false)
    map = {
      1 => '1-3',
      2 => '4-7',
      3 => '8-11',
      4 => '12 or more',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.36.1
  def exit_action(id, reverse=false)
    map = {
      0 => 'No',
      1 => 'Yes',
      9 => 'Client refused',
    }

    _translate map, id, reverse
  end

  # 4.37.1
  def project_completion_status(id, reverse=false)
    map = {
      1 => 'Completed project',
      2 => 'Youth voluntarily left early',
      3 => 'Youth was expelled or otherwise involuntarily discharged from project',
    }

    _translate map, id, reverse
  end

  # 4.37.A
  def early_exit_reason(id, reverse=false)
    map = {
      1 => 'Left for other opportunities - independent living',
      2 => 'Left for other opportunities - education',
      3 => 'Left for other opportunities - military',
      4 => 'Left for other opportunities - other',
      5 => 'Needs could not be met by project',
    }

    _translate map, id, reverse
  end

  # 4.37.B
  def expelled_reason(id, reverse=false)
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

  # 4.39
  def no_assistance_reason(id, reverse=false)
    map = {
      1 => 'Applied; decision pending',
      2 => 'Applied; client not eligible',
      3 => 'Client did not apply',
      4 => 'Insurance type not applicable for this client',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.41.11
  def military_branch(id, reverse=false)
    map = {
      1 => 'Army',
      2 => 'Air Force',
      3 => 'Navy',
      4 => 'Marines',
      6 => 'Coast Guard',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.41.12
  def discharge_status(id, reverse=false)
    map = {
      1 => 'Honorable',
      2 => 'General under honorable conditions',
      4 => 'Bad conduct',
      5 => 'Dishonorable',
      6 => 'Under other than honorable conditions (OTH)',
      7 => 'Uncharacterized',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.42.1
  def percent_a_m_i(id, reverse=false)
    map = {
      1 => 'Less than 30%',
      2 => '30% to 50%',
      3 => 'Greater than 50%',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.43.5
  def address_data_quality(id, reverse=false)
    map = {
      1 => 'Full address',
      2 => 'Incomplete or estimated address',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.47.B
  def t_cell_source_viral_load_source(id, reverse=false)
    map = {
      1 => 'Medical Report',
      2 => 'Client Report',
      3 => 'Other',
    }

    _translate map, id, reverse
  end

  # 4.47.3
  def viral_load_available(id, reverse=false)
    map = {
      0 => 'Not available',
      1 => 'Available',
      2 => 'Undetectable',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.48.1
  def no_points_yes(id, reverse=false)
    map = {
      0 => 'No (0 points)',
      1 => 'Yes',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.48.2
  def time_to_housing_loss(id, reverse=false)
    map = {
      0 => '0-6 days',
      1 => '7-13 days',
      2 => '14-21 days',
      3 => 'More than 21 days (0 points)',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.48.4
  def annual_percent_a_m_i(id, reverse=false)
    map = {
      0 => '0-14% of AMI for household size',
      1 => '15-30% of AMI for household size',
      2 => 'More than 30% of AMI for household size (0 points)',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.48.7
  def eviction_history(id, reverse=false)
    map = {
      0 => '4 or more prior rental evictions',
      1 => '2-3 prior rental evictions',
      2 => '1 prior rental eviction',
      3 => 'No prior rental evictions (0 points)',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.48.9
  def literal_homeless_history(id, reverse=false)
    map = {
      0 => '4 or more times or total of at least 12 months in past three years',
      1 => '2-3 times in past three years',
      2 => '1 time in past three years',
      3 => '4 or more times or total of at least 12 months in past three years',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 4.49.1
  def crisis_services_use(id, reverse=false)
    map = {
      0 => '0',
      1 => '1-2',
      2 => '3-5',
      3 => '6-10',
      4 => '11-20',
      5 => 'More than 20',
      8 => 'Client doesn’t know',
      9 => 'Client refused',
      99 => 'Data not collected',
    }

    _translate map, id, reverse
  end

  # 5.3.1
  def data_collection_stage(id, reverse=false)
    map = {
      1 => 'Project entry',
      2 => 'Update',
      3 => 'Project exit',
      5 => 'Annual assessment',
    }

    _translate map, id, reverse
  end
end