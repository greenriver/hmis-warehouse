###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module HudLists
  module_function

  # 1.1
  def export_period_type_map
    {
      1 => 'Updated',
      2 => 'Effective',
      3 => 'Reporting period',
      4 => 'Other',
    }.freeze
  end

  # 1.2
  def export_directive_map
    {
      1 => 'Delta refresh',
      2 => 'Full refresh',
      3 => 'Other',
    }.freeze
  end

  # 1.3
  def disability_type_map
    {
      5 => 'Physical disability',
      6 => 'Developmental disability',
      7 => 'Chronic health condition',
      8 => 'HIV/AIDS',
      9 => 'Mental health disorder',
      10 => 'Substance use disorder',
    }.freeze
  end

  # 1.4
  def record_type_map
    {
      12 => 'Contact 12',
      13 => 'Contact 13',
      141 => 'PATH Service',
      142 => 'RHY Service Connections',
      143 => 'HOPWA Service',
      144 => 'SSVF Service',
      151 => 'HOPWA Financial Assistance',
      152 => 'SSVF Financial Assistance',
      161 => 'PATH Referral',
      162 => 'RHY Referral',
      200 => 'Bed Night',
      210 => 'HUD-VASH OTH Voucher Tracking',
      300 => 'Moving On Assistance',
    }.freeze
  end

  # 1.5
  def hash_status_map
    {
      1 => 'Unhashed',
      2 => 'SHA-1 RHY',
      3 => 'Hashed - other',
      4 => 'SHA-256 (RHY)',
    }.freeze
  end

  # 1.6
  def race_none_map
    {
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 1.7
  def no_yes_missing_map
    {
      0 => 'No',
      1 => 'Yes',
      99 => 'Data not collected',
    }.freeze
  end

  # 1.8
  def no_yes_reasons_for_missing_data_map
    {
      0 => 'No',
      1 => 'Yes',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 1.9
  def source_type_map
    {
      1 => 'CoC HMIS',
      2 => 'Standalone/agency-specific application',
      3 => 'Data warehouse',
      4 => 'Other',
    }.freeze
  end

  # 2.02.6
  def project_type_map
    {
      1 => 'Emergency Shelter',
      2 => 'Transitional Housing',
      3 => 'PH - Permanent Supportive Housing',
      4 => 'Street Outreach',
      6 => 'Services Only',
      8 => 'Safe Haven',
      9 => 'PH - Housing Only',
      7 => 'Other',
      10 => 'PH - Housing with Services (no disability required for entry)',
      11 => 'Day Shelter',
      12 => 'Homelessness Prevention',
      13 => 'PH - Rapid Re-Housing',
      14 => 'Coordinated Entry',
    }.freeze
  end

  # 2.02.6.brief
  def project_type_brief_map
    {
      1 => 'ES',
      2 => 'TH',
      3 => 'PH - PSH',
      4 => 'SO',
      6 => 'SSO',
      8 => 'SH',
      9 => 'PH - PH',
      7 => 'Other',
      10 => 'PH - OPH',
      11 => 'Day Shelter',
      12 => 'HP',
      13 => 'PH - RRH',
      14 => 'CE',
    }.freeze
  end

  # 2.02.8
  def target_population_map
    {
      1 => 'Domestic violence victims',
      3 => 'Persons with HIV/AIDS',
      4 => 'Not applicable',
    }.freeze
  end

  # 2.02.9
  def hopwa_med_assisted_living_fac_map
    {
      0 => 'No',
      1 => 'Yes',
      2 => 'Non-HOPWA Funded Project',
    }.freeze
  end

  # 2.02.C
  def tracking_method_map
    {
      0 => 'Entry/Exit Date',
      3 => 'Night-by-Night',
    }.freeze
  end

  # 2.02.D
  def housing_type_map
    {
      1 => 'Site-based - single site',
      2 => 'Site-based - clustered / multiple sites',
      3 => 'Tenant-based - scattered site',
    }.freeze
  end

  # 2.03.4
  def geography_type_map
    {
      1 => 'Urban',
      2 => 'Suburban',
      3 => 'Rural',
      99 => 'Unknown / data not collected',
    }.freeze
  end

  # 2.06.1
  def funding_source_map
    {
      1 => 'HUD: CoC - Homelessness Prevention (High Performing Communities Only)',
      2 => 'HUD: CoC - Permanent Supportive Housing',
      3 => 'HUD: CoC - Rapid Re-Housing',
      4 => 'HUD: CoC - Supportive Services Only',
      5 => 'HUD: CoC - Transitional Housing',
      6 => 'HUD: CoC - Safe Haven',
      7 => 'HUD: CoC - Single Room Occupancy (SRO)',
      8 => 'HUD: ESG - Emergency Shelter (operating and/or essential services)',
      9 => 'HUD: ESG - Homelessness Prevention',
      10 => 'HUD: ESG - Rapid Rehousing',
      11 => 'HUD: ESG - Street Outreach',
      12 => 'HUD: Rural Housing Stability Assistance Program',
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
      47 => 'HUD: ESG - CV',
      48 => 'HUD: HOPWA - CV',
      49 => 'HUD: CoC - Joint Component RRH/PSH',
      50 => 'HUD: HOME',
      51 => 'HUD: HOME (ARP)',
      52 => 'HUD: PIH (Emergency Housing Voucher)',
      53 => 'HUD: ESG - RUSH',
    }.freeze
  end

  # 2.07.4
  def household_type_map
    {
      1 => 'Households without children',
      3 => 'Households with at least one adult and one child',
      4 => 'Households with only children',
    }.freeze
  end

  # 2.07.5
  def bed_type_map
    {
      1 => 'Facility-based',
      2 => 'Voucher',
      3 => 'Other',
    }.freeze
  end

  # 2.07.6
  def availability_map
    {
      1 => 'Year-round',
      2 => 'Seasonal',
      3 => 'Overflow',
    }.freeze
  end

  # 2.7.B
  def youth_age_group_map
    {
      1 => 'Only under age 18',
      2 => 'Only ages 18 to 24',
      3 => 'Only youth under age 24 (both of the above)',
    }.freeze
  end

  # 3.01.5
  def name_data_quality_map
    {
      1 => 'Full name reported',
      2 => 'Partial, street name, or code name reported',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 3.02.2
  def ssn_data_quality_map
    {
      1 => 'Full SSN reported',
      2 => 'Approximate or partial SSN reported',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 3.03.2
  def dob_data_quality_map
    {
      1 => 'Full DOB reported',
      2 => 'Approximate or partial DOB reported',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 3.05.1
  def ethnicity_map
    {
      0 => 'Non-Hispanic/Non-Latin(a)(o)(x)',
      1 => 'Hispanic/Latin(a)(o)(x)',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 3.12.1
  def destination_map
    {
      1 => 'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or RHY-funded Host Home shelter',
      2 => 'Transitional housing for homeless persons (including homeless youth)',
      3 => 'Permanent housing (other than RRH) for formerly homeless persons',
      4 => 'Psychiatric hospital or other psychiatric facility',
      5 => 'Substance abuse treatment facility or detox center',
      6 => 'Hospital or other residential non-psychiatric medical facility',
      7 => 'Jail, prison or juvenile detention facility',
      8 => "Client doesn't know",
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
      35 => "Staying or living in a family member's room, apartment or house",
      36 => "Staying or living in a friend's room, apartment or house",
      37 => 'Worker unable to determine',
      99 => 'Data not collected',
    }.freeze
  end

  # 3.12.1
  def living_situation_map
    {
      1 => 'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or RHY-funded Host Home shelter',
      2 => 'Transitional housing for homeless persons (including homeless youth)',
      3 => 'Permanent housing (other than RRH) for formerly homeless persons',
      4 => 'Psychiatric hospital or other psychiatric facility',
      5 => 'Substance abuse treatment facility or detox center',
      6 => 'Hospital or other residential non-psychiatric medical facility',
      7 => 'Jail, prison or juvenile detention facility',
      8 => "Client doesn't know",
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
      27 => 'Interim Housing',
      28 => 'Rental by client, with GPD TIP housing subsidy',
      29 => 'Residential project or halfway house with no homeless criteria',
      30 => 'No exit interview completed',
      31 => 'Rental by client, with RRH or equivalent subsidy',
      32 => 'Host Home (non-crisis)',
      33 => 'Rental by client, with HCV voucher (tenant or project based)',
      34 => 'Rental by client in a public housing unit',
      35 => "Staying or living in a family member's room, apartment or house",
      36 => "Staying or living in a friend's room, apartment or house",
      37 => 'Worker unable to determine',
      99 => 'Data not collected',
    }.freeze
  end

  # 3.15.1
  def relationship_to_ho_h_map
    {
      1 => 'Self (head of household)',
      2 => 'Child',
      3 => 'Spouse or partner',
      4 => 'Other relative',
      5 => 'Unrelated household member',
      99 => 'Data not collected',
    }.freeze
  end

  # 3.6.1
  def gender_map
    {
      0 => 'Female',
      1 => 'Male',
      4 => 'A gender other than singularly female or male (e.g., non-binary, genderfluid, agender, culturally specific gender)',
      5 => 'Transgender',
      6 => 'Questioning',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 3.917.2
  def residence_prior_length_of_stay_map
    {
      2 => 'One week or more, but less than one month',
      3 => 'One month or more, but less than 90 days',
      4 => '90 days or more but less than one year',
      5 => 'One year or longer',
      8 => "Client doesn't know",
      9 => 'Client refused',
      10 => 'One night or less',
      11 => 'Two to six nights',
      99 => 'Data not collected',
    }.freeze
  end

  # 3.917.4
  def times_homeless_past_three_years_map
    {
      1 => 'One time',
      2 => 'Two times',
      3 => 'Three times',
      4 => 'Four or more times',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 3.917.5
  def months_homeless_past_three_years_map
    {
      8 => "Client doesn't know",
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
    }.freeze
  end

  # 4.04.A
  def reason_not_insured_map
    {
      1 => 'Applied; decision pending',
      2 => 'Applied; client not eligible',
      3 => 'Client did not apply',
      4 => 'Insurance type N/A for this client',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 4.1.1
  def housing_status_map
    {
      1 => 'Category 1 - Homeless',
      2 => 'Category 2 - At imminent risk of losing housing',
      3 => 'At-risk of homelessness',
      4 => 'Stably housed',
      5 => 'Category 3 - Homeless only under other federal statutes',
      6 => 'Category 4 - Fleeing domestic violence',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 4.10.2
  def disability_response_map
    {
      0 => 'No',
      1 => 'Alcohol use disorder',
      2 => 'Drug use disorder',
      3 => 'Both alcohol and drug use disorders',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 4.11.A
  def when_dv_occurred_map
    {
      1 => 'Within the past three months',
      2 => 'Three to six months ago (excluding six months exactly)',
      3 => 'Six months to one year ago (excluding one year exactly)',
      4 => 'One year or more',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 4.12.2
  def contact_location_map
    {
      1 => 'Place not meant for habitation',
      2 => 'Service setting, non-residential',
      3 => 'Service setting, residential',
    }.freeze
  end

  # 4.14
  def bed_night_map
    {
      200 => 'BedNight',
    }.freeze
  end

  # 4.14.B
  def rhy_services_map
    {
      2 => 'Community service/service learning (CSL)',
      5 => 'Education',
      6 => 'Employment and training services',
      7 => 'Criminal justice /legal services',
      8 => 'Life skills training',
      10 => 'Parenting education for youth with children',
      12 => 'Post-natal care',
      13 => 'Pre-natal care',
      14 => 'Health/medical care',
      17 => 'Substance use disorder treatment',
      18 => 'Substance use disorder/Prevention Services',
      26 => 'Home-based Services',
      27 => 'Post-natal newborn care (wellness exams; immunizations)',
      28 => 'STD Testing',
      29 => 'Street-based Services',
    }.freeze
  end

  # 4.15.B
  def ssvf_financial_assistance_map
    {
      1 => 'Rental assistance',
      2 => 'Security deposit',
      3 => 'Utility deposit',
      4 => 'Utility fee payment assistance',
      5 => 'Moving costs',
      8 => 'Transportation services: tokens/vouchers',
      9 => 'Transportation services: vehicle repair/maintenance',
      10 => 'Child care',
      11 => 'General housing stability assistance - emergency supplies',
      12 => 'General housing stability assistance',
      14 => 'Emergency housing assistance',
      15 => 'Extended Shallow Subsidy - Rental Assistance',
      16 => 'Food Assistance',
    }.freeze
  end

  # 4.18.1
  def housing_assessment_disposition_map
    {
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
    }.freeze
  end

  # 4.19.3
  def assessment_type_map
    {
      1 => 'Phone',
      2 => 'Virtual',
      3 => 'In Person',
    }.freeze
  end

  # 4.19.4
  def assessment_level_map
    {
      1 => 'Crisis Needs Assessment',
      2 => 'Housing Needs Assessment',
    }.freeze
  end

  # 4.19.7
  def prioritization_status_map
    {
      1 => 'Placed on prioritization list',
      2 => 'Not placed on prioritization list',
    }.freeze
  end

  # 4.20.2
  def event_type_map
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
  def referral_result_map
    {
      1 => 'Successful referral: client accepted',
      2 => 'Unsuccessful referral: client rejected',
      3 => 'Unsuccessful referral: provider rejected',
    }.freeze
  end

  # 4.33.A
  def incarcerated_parent_status_map
    {
      1 => 'One parent / legal guardian is incarcerated',
      2 => 'Both parents / legal guardians are incarcerated',
      3 => 'The only parent / legal guardian is incarcerated',
      99 => 'Data not collected',
    }.freeze
  end

  # 4.36.1
  def exit_action_map
    {
      0 => 'No',
      1 => 'Yes',
      9 => 'Client refused',
    }.freeze
  end

  # 4.37.A
  def early_exit_reason_map
    {
      1 => 'Left for other opportunities - independent living',
      2 => 'Left for other opportunities - education',
      3 => 'Left for other opportunities - military',
      4 => 'Left for other opportunities - other',
      5 => 'Needs could not be met by project',
    }.freeze
  end

  # 4.49.1
  def crisis_services_use_map
    {
      0 => '0',
      1 => '1-2',
      2 => '3-5',
      3 => '6-10',
      4 => '11-20',
      5 => 'More than 20',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 4.9.D
  def path_how_confirmed_map
    {
      1 => 'Unconfirmed; presumptive or self-report',
      2 => 'Confirmed through assessment and clinical evaluation',
      3 => 'Confirmed by prior evaluation or clinical records',
      99 => 'Data not collected',
    }.freeze
  end

  # 4.9.E
  def pathsmi_information_map
    {
      0 => 'No',
      1 => 'Unconfirmed; presumptive or self-report',
      2 => 'Confirmed through assessment and clinical evaluation',
      3 => 'Confirmed by prior evaluation or clinical records',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # 5.03.1
  def data_collection_stage_map
    {
      1 => 'Project entry',
      2 => 'Update',
      3 => 'Project exit',
      5 => 'Annual assessment',
      6 => 'Post-exit',
    }.freeze
  end

  # C1.1
  def wellbeing_agreement_map
    {
      0 => 'Strongly disagree',
      1 => 'Somewhat disagree',
      2 => 'Neither agree nor disagree',
      3 => 'Somewhat agree',
      4 => 'Strongly agree',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # C1.2
  def feeling_frequency_map
    {
      0 => 'Not at all',
      1 => 'Once a month',
      2 => 'Several times a month',
      3 => 'Several times a week',
      4 => 'At least every day',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # C2.2
  def moving_on_assistance_map
    {
      1 => 'Subsidized housing application assistance',
      2 => 'Financial assistance for Moving On (e.g., security deposit, moving expenses)',
      3 => 'Non-financial assistance for Moving On (e.g., housing navigation, transition support)',
      4 => 'Housing referral/placement',
      5 => 'Other',
    }.freeze
  end

  # C3.2
  def current_school_attended_map
    {
      0 => 'Not currently enrolled in any school or educational course',
      1 => 'Currently enrolled but NOT attending regularly (when school or the course is in session)',
      2 => 'Currently enrolled and attending regularly (when school or the course is in session)',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # C3.A
  def most_recent_ed_status_map
    {
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
    }.freeze
  end

  # C3.B
  def current_ed_status_map
    {
      0 => 'Pursuing a high school diploma or GED',
      1 => "Pursuing Associate's Degree",
      2 => "Pursuing Bachelor's Degree",
      3 => 'Pursuing Graduate Degree',
      4 => 'Pursuing other post-secondary credential',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # P1.2
  def path_services_map
    {
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
    }.freeze
  end

  # P2.2
  def path_referral_map
    {
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
    }.freeze
  end

  # P2.A
  def path_referral_outcome_map
    {
      1 => 'Attained',
      2 => 'Not attained',
      3 => 'Unknown',
    }.freeze
  end

  # P3.A
  def reason_not_enrolled_map
    {
      1 => 'Client was found ineligible for PATH',
      2 => 'Client was not enrolled for other reason(s)',
    }.freeze
  end

  # R1.1
  def referral_source_map
    {
      1 => 'Self-referral',
      2 => 'Individual: Parent/Guardian/Relative/Friend/Foster Parent/Other Individual',
      7 => 'Outreach Project',
      8 => "Client doesn't know",
      9 => 'Client refused',
      10 => 'Outreach project: other',
      11 => 'Temporary Shelter',
      18 => 'Residential Project',
      28 => 'Hotline',
      30 => 'Child Welfare/CPS',
      34 => 'Juvenile Justice',
      35 => 'Law Enforcement/ Police',
      37 => 'Mental Hospital',
      38 => 'School',
      39 => 'Other organization',
      99 => 'Data not collected',
    }.freeze
  end

  # R11.A
  def rhy_numberof_years_map
    {
      1 => 'Less than one year',
      2 => '1 to 2 years',
      3 => '3 to 5 or more years',
      99 => 'Data not collected',
    }.freeze
  end

  # R14.2
  def rhy_referral_map
    {
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
    }.freeze
  end

  # R15.B
  def count_exchange_for_sex_map
    {
      1 => '1-3',
      2 => '4-7',
      3 => '8-11',
      4 => '12 or more',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # R17.1
  def project_completion_status_map
    {
      1 => 'Completed project',
      2 => 'Youth voluntarily left early',
      3 => 'Youth was expelled or otherwise involuntarily discharged from project',
    }.freeze
  end

  # R17.A
  def expelled_reason_map
    {
      1 => 'Criminal activity/destruction of property/violence',
      2 => 'Non-compliance with project rules',
      3 => 'Non-payment of rent/occupancy charge',
      4 => 'Reached maximum time allowed by project',
      5 => 'Project terminated',
      6 => 'Unknown/disappeared',
    }.freeze
  end

  # R19.A
  def worker_response_map
    {
      0 => 'No',
      1 => 'Yes',
      2 => 'Worker does not know',
    }.freeze
  end

  # R2.A
  def reason_no_services_map
    {
      1 => 'Out of age range',
      2 => 'Ward of the state',
      3 => 'Ward of the criminal justice system',
      4 => 'Other',
      99 => 'Data not collected',
    }.freeze
  end

  # R20.2
  def aftercare_provided_map
    {
      0 => 'No',
      1 => 'Yes',
      9 => 'Client refused',
    }.freeze
  end

  # R3.1
  def sexual_orientation_map
    {
      1 => 'Heterosexual',
      2 => 'Gay',
      3 => 'Lesbian',
      4 => 'Bisexual',
      5 => 'Questioning / unsure',
      6 => 'Other',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # R4.1
  def last_grade_completed_map
    {
      1 => 'Less than grade 5',
      2 => 'Grades 5-6',
      3 => 'Grades 7-8',
      4 => 'Grades 9-11',
      5 => 'Grade 12',
      6 => 'School program does not have grade levels',
      7 => 'GED',
      8 => "Client doesn't know",
      9 => 'Client refused',
      10 => 'Some college',
      11 => "Associate's degree",
      12 => "Bachelor's degree",
      13 => 'Graduate degree',
      14 => 'Vocational certification',
      99 => 'Data not collected',
    }.freeze
  end

  # R5.1
  def school_status_map
    {
      1 => 'Attending school regularly',
      2 => 'Attending school irregularly',
      3 => 'Graduated from high school',
      4 => 'Obtained GED',
      5 => 'Dropped out',
      6 => 'Suspended',
      7 => 'Expelled',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # R6.A
  def employment_type_map
    {
      1 => 'Full-time',
      2 => 'Part-time',
      3 => 'Seasonal / sporadic (including day labor)',
      99 => 'Data not collected',
    }.freeze
  end

  # R6.B
  def not_employed_reason_map
    {
      1 => 'Looking for work',
      2 => 'Unable to work',
      3 => 'Not looking for work',
      99 => 'Data not collected',
    }.freeze
  end

  # R7.1
  def health_status_map
    {
      1 => 'Excellent',
      2 => 'Very good',
      3 => 'Good',
      4 => 'Fair',
      5 => 'Poor',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # V1.11
  def military_branch_map
    {
      1 => 'Army',
      2 => 'Air Force',
      3 => 'Navy',
      4 => 'Marines',
      6 => 'Coast Guard',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # V1.12
  def discharge_status_map
    {
      1 => 'Honorable',
      2 => 'General under honorable conditions',
      4 => 'Bad conduct',
      5 => 'Dishonorable',
      6 => 'Under other than honorable conditions (OTH)',
      7 => 'Uncharacterized',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # V2.2
  def ssvf_services_map
    {
      1 => 'Outreach services',
      2 => 'Case management services',
      3 => 'Assistance obtaining VA benefits',
      4 => 'Assistance obtaining/coordinating other public benefits',
      5 => 'Direct provision of other public benefits',
      6 => 'Other (non-TFA) supportive service approved by VA',
    }.freeze
  end

  # V2.3
  def hopwa_financial_assistance_map
    {
      1 => 'Rental assistance',
      2 => 'Security deposits',
      3 => 'Utility deposits',
      4 => 'Utility payments',
      7 => 'Mortgage assistance',
    }.freeze
  end

  # V2.A
  def ssvf_sub_type3_map
    {
      1 => 'VA vocational and rehabilitation counseling',
      2 => 'Employment and training services',
      3 => 'Educational assistance',
      4 => 'Health care services',
    }.freeze
  end

  # V2.B
  def ssvf_sub_type4_map
    {
      1 => 'Health care services',
      2 => 'Daily living services',
      3 => 'Personal financial planning services',
      4 => 'Transportation services',
      5 => 'Income support services',
      6 => 'Fiduciary and representative payee services',
      7 => 'Legal services - child support',
      8 => 'Legal services - eviction prevention',
      9 => 'Legal services - outstanding fines and penalties',
      10 => "Legal services - restore / acquire driver's license",
      11 => 'Legal services - other',
      12 => 'Child care',
      13 => 'Housing counseling',
    }.freeze
  end

  # V2.C
  def ssvf_sub_type5_map
    {
      1 => 'Personal financial planning services',
      2 => 'Transportation services',
      3 => 'Income support services',
      4 => 'Fiduciary and representative payee services',
      5 => 'Legal services - child support',
      6 => 'Legal services - eviction prevention',
      7 => 'Legal services - outstanding fines and penalties',
      8 => "Legal services - restore / acquire driver's license",
      9 => 'Legal services - other',
      10 => 'Child care',
      11 => 'Housing counseling',
    }.freeze
  end

  # V4.1
  def percent_ami_map
    {
      1 => 'Less than 30%',
      2 => '30% to 50%',
      3 => 'Greater than 50%',
      99 => 'Data not collected',
    }.freeze
  end

  # V5.5
  def address_data_quality_map
    {
      1 => 'Full address',
      2 => 'Incomplete or estimated address',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # V6.1
  def vamcs_station_number_map
    {
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
      523 => '(523) VA Boston HCS, MA',
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
      544 => '(544) Columbia, SC',
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
      568 => '(568) Black Hills HCS, SD',
      570 => '(570) Fresno, CA',
      573 => '(573) Gainesville, FL',
      575 => '(575) Grand Junction, CO',
      578 => '(578) Hines, IL',
      580 => '(580) Houston, TX',
      581 => '(581) Huntington, WV',
      583 => '(583) Indianapolis, IN',
      585 => '(585) Iron Mountain, MI',
      586 => '(586) Jackson, MS',
      589 => '(589) Kansas City, MO',
      590 => '(590) Hampton, VA',
      593 => '(593) Las Vegas, NV',
      595 => '(595) Lebanon, PA',
      596 => '(596) Lexington, KY',
      598 => '(598) Little Rock, AR',
      600 => '(600) Long Beach, CA',
      603 => '(603) Louisville, KY',
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
      640 => '(640) Palo Alto, CA',
      642 => '(642) Philadelphia, PA',
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
      '636A6' => '(636A6) Central Iowa, IA',
      '636A8' => '(636A8) Iowa City, IA',
      '657A4' => '(657A4) Poplar Bluff, MO',
      '657A5' => '(657A5) Marion, IL',
      99 => 'not collected',
    }.freeze
  end

  # V7.1
  def no_points_yes_map
    {
      0 => 'No (0 points)',
      1 => 'Yes',
      99 => 'Data not collected',
    }.freeze
  end

  # V7.A
  def time_to_housing_loss_map
    {
      0 => '1-6 days',
      1 => '7-13 days',
      2 => '14-21 days',
      3 => 'More than 21 days',
      99 => 'Data not collected',
    }.freeze
  end

  # V7.B
  def annual_percent_ami_map
    {
      0 => '$0 (i.e., not employed, not receiving cash benefits, no other current income)',
      1 => '1-14% of Area Median Income (AMI) for household size',
      2 => '15-30% of AMI for household size',
      3 => 'More than 30% of AMI for household size',
      99 => 'Data not collected',
    }.freeze
  end

  # V7.C
  def literal_homeless_history_map
    {
      0 => 'Most recent episode occurred in the last year',
      1 => 'Most recent episode occurred more than one year ago',
      2 => 'None',
      99 => 'Data not collected',
    }.freeze
  end

  # V7.G
  def eviction_history_map
    {
      0 => 'No prior rental evictions',
      1 => '1 prior rental eviction',
      2 => '2 or more prior rental evictions',
      99 => 'Data not collected',
    }.freeze
  end

  # V7.I
  def incarcerated_adult_map
    {
      0 => 'Not incarcerated',
      1 => 'Incarcerated once',
      2 => 'Incarcerated two or more times',
      99 => 'Data not collected',
    }.freeze
  end

  # V7.O
  def dependent_under6_map
    {
      0 => 'No',
      1 => 'Youngest child is under 1 year old',
      2 => 'Youngest child is 1 to 6 years old and/or one or more children (any age) require significant care',
      99 => 'Data not collected',
    }.freeze
  end

  # V8.1
  def voucher_tracking_map
    {
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
    }.freeze
  end

  # V9.1
  def cm_exit_reason_map
    {
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
    }.freeze
  end

  # W1.2
  def hopwa_services_map
    {
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
    }.freeze
  end

  # W3
  def no_assistance_reason_map
    {
      1 => 'Applied; decision pending',
      2 => 'Applied; client not eligible',
      3 => 'Client did not apply',
      4 => 'Insurance type not applicable for this client',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # W4.3
  def viral_load_available_map
    {
      0 => 'Not available',
      1 => 'Available',
      2 => 'Undetectable',
      8 => "Client doesn't know",
      9 => 'Client refused',
      99 => 'Data not collected',
    }.freeze
  end

  # W4.B
  def t_cell_source_viral_load_source_map
    {
      1 => 'Medical Report',
      2 => 'Client Report',
      3 => 'Other',
    }.freeze
  end

  # W5.1
  def housing_assessment_at_exit_map
    {
      1 => 'Able to maintain the housing they had at project entry',
      2 => 'Moved to new housing unit',
      3 => 'Moved in with family/friends on a temporary basis',
      4 => 'Moved in with family/friends on a permanent basis',
      5 => 'Moved to a transitional or temporary housing facility or program',
      6 => 'Client became homeless - moving to a shelter or other place unfit for human habitation',
      7 => 'Client went to jail/prison',
      8 => "Client doesn't know",
      9 => 'Client refused',
      10 => 'Client died',
      99 => 'Data not collected',
    }.freeze
  end

  # W5.A
  def subsidy_information_map
    {
      1 => 'Without a subsidy 1',
      2 => 'With the subsidy they had at project entry 1',
      3 => 'With an on-going subsidy acquired since project entry 1',
      4 => 'But only with other financial assistance 1',
      11 => 'With on-going subsidy 2',
      12 => 'Without an on-going subsidy 2',
    }.freeze
  end

  # ad_hoc_yes_no
  def ad_hoc_yes_no_map
    {
      0 => 'No',
      1 => 'Yes',
      8 => "Don't Know",
      9 => 'Refused',
      99 => 'Data not collected',
    }.freeze
  end

  # race
  def race_map
    {
      'AmIndAKNative' => 'American Indian, Alaska Native, or Indigenous',
      'Asian' => 'Asian or Asian American',
      'BlackAfAmerican' => 'Black, African American, or African',
      'NativeHIPacific' => 'Native Hawaiian or Pacific Islander',
      'White' => 'White',
      'RaceNone' => "Doesn't Know, refused, or not collected",
    }.freeze
  end

  def hud_code_to_function_map
    {
      "1.1": :export_period_type_map,
      "1.2": :export_directive_map,
      "1.3": :disability_type_map,
      "1.4": :record_type_map,
      "1.5": :hash_status_map,
      "1.6": :race_none_map,
      "1.7": :no_yes_missing_map,
      "1.8": :no_yes_reasons_for_missing_data_map,
      "1.9": :source_type_map,
      "2.02.6": :project_type_map,
      "2.02.6.brief": :project_type_brief_map,
      "2.02.8": :target_population_map,
      "2.02.9": :hopwa_med_assisted_living_fac_map,
      "2.02.C": :tracking_method_map,
      "2.02.D": :housing_type_map,
      "2.03.4": :geography_type_map,
      "2.06.1": :funding_source_map,
      "2.07.4": :household_type_map,
      "2.07.5": :bed_type_map,
      "2.07.6": :availability_map,
      "2.7.B": :youth_age_group_map,
      "3.01.5": :name_data_quality_map,
      "3.02.2": :ssn_data_quality_map,
      "3.03.2": :dob_data_quality_map,
      "3.05.1": :ethnicity_map,
      "3.12.1": :living_situation_map,
      "3.15.1": :relationship_to_ho_h_map,
      "3.6.1": :gender_map,
      "3.917.2": :residence_prior_length_of_stay_map,
      "3.917.4": :times_homeless_past_three_years_map,
      "3.917.5": :months_homeless_past_three_years_map,
      "4.04.A": :reason_not_insured_map,
      "4.1.1": :housing_status_map,
      "4.10.2": :disability_response_map,
      "4.11.A": :when_dv_occurred_map,
      "4.12.2": :contact_location_map,
      "4.14": :bed_night_map,
      "4.14.B": :rhy_services_map,
      "4.15.B": :ssvf_financial_assistance_map,
      "4.18.1": :housing_assessment_disposition_map,
      "4.19.3": :assessment_type_map,
      "4.19.4": :assessment_level_map,
      "4.19.7": :prioritization_status_map,
      "4.20.2": :event_type_map,
      "4.20.D": :referral_result_map,
      "4.33.A": :incarcerated_parent_status_map,
      "4.36.1": :exit_action_map,
      "4.37.A": :early_exit_reason_map,
      "4.49.1": :crisis_services_use_map,
      "4.9.D": :path_how_confirmed_map,
      "4.9.E": :pathsmi_information_map,
      "5.03.1": :data_collection_stage_map,
      "C1.1": :wellbeing_agreement_map,
      "C1.2": :feeling_frequency_map,
      "C2.2": :moving_on_assistance_map,
      "C3.2": :current_school_attended_map,
      "C3.A": :most_recent_ed_status_map,
      "C3.B": :current_ed_status_map,
      "P1.2": :path_services_map,
      "P2.2": :path_referral_map,
      "P2.A": :path_referral_outcome_map,
      "P3.A": :reason_not_enrolled_map,
      "R1.1": :referral_source_map,
      "R11.A": :rhy_numberof_years_map,
      "R14.2": :rhy_referral_map,
      "R15.B": :count_exchange_for_sex_map,
      "R17.1": :project_completion_status_map,
      "R17.A": :expelled_reason_map,
      "R19.A": :worker_response_map,
      "R2.A": :reason_no_services_map,
      "R20.2": :aftercare_provided_map,
      "R3.1": :sexual_orientation_map,
      "R4.1": :last_grade_completed_map,
      "R5.1": :school_status_map,
      "R6.A": :employment_type_map,
      "R6.B": :not_employed_reason_map,
      "R7.1": :health_status_map,
      "V1.11": :military_branch_map,
      "V1.12": :discharge_status_map,
      "V2.2": :ssvf_services_map,
      "V2.3": :hopwa_financial_assistance_map,
      "V2.A": :ssvf_sub_type3_map,
      "V2.B": :ssvf_sub_type4_map,
      "V2.C": :ssvf_sub_type5_map,
      "V4.1": :percent_ami_map,
      "V5.5": :address_data_quality_map,
      "V6.1": :vamcs_station_number_map,
      "V7.1": :no_points_yes_map,
      "V7.A": :time_to_housing_loss_map,
      "V7.B": :annual_percent_ami_map,
      "V7.C": :literal_homeless_history_map,
      "V7.G": :eviction_history_map,
      "V7.I": :incarcerated_adult_map,
      "V7.O": :dependent_under6_map,
      "V8.1": :voucher_tracking_map,
      "V9.1": :cm_exit_reason_map,
      "W1.2": :hopwa_services_map,
      "W3": :no_assistance_reason_map,
      "W4.3": :viral_load_available_map,
      "W4.B": :t_cell_source_viral_load_source_map,
      "W5.1": :housing_assessment_at_exit_map,
      "W5.A": :subsidy_information_map,
      "ad_hoc_yes_no": :ad_hoc_yes_no_map,
      "race": :race_map,
    }.freeze
  end
end
