###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# elements from HUD 2022 and 2024 that were deprecated but we preserve for backwards compatibility
module HudUtility2026Deprecations
  extend ActiveSupport::Concern
  # 2.06.1
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
      9 => 'HUD: ESG - Homelessness Prevention',
      10 => 'HUD: ESG - Rapid Rehousing',
      11 => 'HUD: ESG - Street Outreach',
      12 => 'HUD: Rural Housing Stability Assistance Program [Deprecated]',
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
      47 => 'HUD: ESG - CV [Deprecated]',
      48 => 'HUD: HOPWA - CV [Deprecated]',
      49 => 'HUD: CoC - Joint Component RRH/PSH [Deprecated]',
      50 => 'HUD: HOME',
      51 => 'HUD: HOME (ARP)',
      52 => 'HUD: PIH (Emergency Housing Voucher)',
      53 => 'HUD: ESG - RUSH',
      54 => 'HUD: Unsheltered Special NOFO',
      55 => 'HUD: Rural Special NOFO',
      56 => 'HUD: CoC Builds',
    }.freeze
  end

  # V3.3
  def ssvf_financial_assistance_options
    {
      1 => 'Rental assistance',
      2 => 'Security deposit',
      3 => 'Utility deposit',
      4 => 'Utility fee payment assistance',
      5 => 'Moving costs',
      8 => 'Transportation services: tokens/vouchers',
      9 => 'Transportation services: vehicle repair/maintenance',
      10 => 'Child care',
      11 => 'General housing stability assistance - emergency supplies [Deprecated]',
      12 => 'General housing stability assistance',
      14 => 'Emergency housing assistance',
      15 => 'Shallow Subsidy - Financial Assistance',
      16 => 'Food Assistance',
      17 => 'Landlord Incentive',
      18 => 'Tenant Incentive',
    }.freeze
  end

  # HUD 2024 gender (retired field)
  # 3.6.1
  def genders
    {
      0 => 'Woman (Girl, if child)',
      1 => 'Man (Boy, if child)',
      2 => 'Culturally Specific Identity (e.g., Two-Spirit)',
      4 => 'Non-Binary',
      5 => 'Transgender',
      6 => 'Questioning',
      3 => 'Different Identity',
      8 => "Client doesn't know",
      9 => 'Client prefers not to answer',
      99 => 'Data not collected',
    }.freeze
  end

  def gender(id, reverse = false, raise_on_missing: false)
    _translate(genders, id, reverse, raise_on_missing: raise_on_missing)
  end

  # 1.6
  def gender_none(id, reverse = false)
    race_none(id, reverse)
  end

  def race_gender_none_options
    race_nones
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

  # HUD 2024 sexual_orientations (retired field)
  # R3.1
  def sexual_orientations
    {
      1 => 'Heterosexual',
      2 => 'Gay',
      3 => 'Lesbian',
      4 => 'Bisexual',
      5 => 'Questioning / unsure',
      6 => 'Other',
      8 => "Client doesn't know",
      9 => 'Client prefers not to answer',
      99 => 'Data not collected',
    }.freeze
  end

  def sexual_orientation(id, reverse = false, raise_on_missing: false)
    _translate(sexual_orientations, id, reverse, raise_on_missing: raise_on_missing)
  end
end
