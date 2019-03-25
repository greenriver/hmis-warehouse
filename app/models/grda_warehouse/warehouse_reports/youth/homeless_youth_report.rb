module GrdaWarehouse::WarehouseReports::Youth
  class HomelessYouthReport

    def initialize(filter)
      @start_date = filter.start
      @end_date = filter.end
    end

    # A. Core Services

    def section_1_scope
      GrdaWarehouse::YouthIntake::Base.
        open_between(start_date: @start_date, end_date: @end_date).
        where(street_outreach_contact: "Yes")
    end

    def one_a
      @one_a ||= get_client_ids(section_1_scope.
        where(housing_status: homeless_statuses))
    end

    def one_b
      @one_b ||= get_client_ids(section_1_scope.
        where(housing_status: 'At risk of homelessness'))
    end

    def section_2_scope
      GrdaWarehouse::YouthIntake::Base.
        open_between(start_date: @start_date, end_date: @end_date).
        where(street_outreach_contact: "No")
    end

    def two_a
      @two_a ||= get_client_ids(section_2_scope.
        where(housing_status: homeless_statuses))
    end

    def two_b
      @two_b ||= get_client_ids(section_2_scope.
        where(housing_status: 'At risk of homelessness'))
    end

    def two_c
      @two_c ||= {}
      groups = section_2_scope.pluck(:how_hear, :client_id).group_by(&:first)
      groups.each do |group, items|
        @two_c[group]  = items.map{ | item | item.last }
      end
      @two_c
    end

    def section_3_intake_scope
      GrdaWarehouse::YouthIntake::Base.
        open_between(start_date: @start_date, end_date: @end_date).
        where(youth_experiencing_homelessness_at_start: "No")
    end

    def three_a
      @three_a ||= get_client_ids(section_3_intake_scope.
        open_after(@start_date).
        where(housing_status: 'At risk of homelessness'))
    end

    def section_3_management_scope
      GrdaWarehouse::Youth::YouthCaseManagement.
        between(start_date: @start_date, end_date: @end_date)
    end

    def three_b
      @three_b ||= get_client_ids(section_3_management_scope) - get_client_ids(section_3_intake_scope)
    end

    def three_c
      @three_c ||= get_client_ids(section_3_intake_scope.
          open_after(@start_date).
          where(housing_status: 'At risk of homelessness', turned_away: true))
    end

    def section_4_intake_scope
      GrdaWarehouse::YouthIntake::Base.
          open_between(start_date: @start_date, end_date: @end_date).
          where(youth_experiencing_homelessness_at_start: "Yes")
    end

    def four_a
      @four_a ||= get_client_ids(section_4_intake_scope.
        open_after(@start_date))
    end

    def four_b
      @four_b ||= get_client_ids(section_4_intake_scope.
        where(housing_status: 'At risk of homelessness'))
    end

    def section_4_management_scope
      GrdaWarehouse::Youth::YouthCaseManagement.
          between(start_date: @start_date, end_date: @end_date)
    end

    def four_c
      @four_c ||= get_client_ids(section_4_management_scope) - get_client_ids(section_4_intake_scope)
    end

    def four_d
      @four_d ||= get_client_ids(section_4_intake_scope.
          open_after(@start_date).
          where(turned_away: true))
    end

    def section_5_assistance_scope
      GrdaWarehouse::Youth::DirectFinancialAssistance.
          between(start_date: @start_date, end_date: @end_date)
    end

    def five_a
      @five_a ||= get_client_ids(section_5_assistance_scope)
    end

    def section_5_intake_scope
      GrdaWarehouse::YouthIntake::Base.
          open_between(start_date: @start_date, end_date: @end_date)
    end

    def five_b
      @five_b ||= get_client_ids(section_5_intake_scope) - five_a
    end

    def five_c
      @five_c ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Move-in costs'))
    end

    def five_d
      @five_d ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Rent'))
    end

    def five_e
      @five_e ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Rent arrears'))
    end

    def five_f
      @five_f ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Utilities'))
    end

    def five_g
      @five_g ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Transportation-related costs'))
    end

    def five_h
      @five_h ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Education-related costs'))
    end

    def five_i
      @five_i ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Legal costs'))
    end

    def five_j
      @five_j ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Child care'))
    end

    def five_k
      @five_k ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Work-related costs'))
    end

    def five_l
      @five_l ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Medical costs'))
    end

    def five_m
      @five_m ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Cell phone costs'))
    end

    def five_n
      @five_n ||= get_client_ids(section_5_assistance_scope.
        where(type_provided: 'Food / Groceries (including our drop-in food pantries)'))
    end

    def five_o
      @five_o ||= {}
      available_types = GrdaWarehouse::Youth::DirectFinancialAssistance.new.available_types - [ 'Other' ]
      groups = section_5_assistance_scope.pluck(:type_provided, :client_id).group_by(&:first)
      groups.each do |group, items|
        next if available_types.include?(group)
        @five_o[group]  = items.map{ | item | item.last }
      end
      @five_o
    end

    def section_6_referral_scope
      GrdaWarehouse::Youth::YouthReferral.
          between(start_date: @start_date, end_date: @end_date)
    end

    def six_a
      @six_a ||= get_client_ids(section_6_referral_scope)
    end

    def six_b
      @six_b ||= get_client_ids(section_6_referral_scope.
        where(referred_to: 'Referred for health services'))
    end

    def six_c
      @six_c ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred for mental health services'))
    end

    def six_d
      @six_d ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred for substance use services'))
    end

    def six_e
      @six_e ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred for employment & job training services'))
    end

    def six_f
      @six_f ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred for education services'))
    end

    def six_g
      @six_g ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred for parenting services'))
    end

    def six_h
      @six_h ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred for domestic violence-related services'))
    end

    def six_i
      @six_i ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred for lifeskills / financial literacy services'))
    end

    def six_j
      @six_j ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred for legal services'))
    end

    def six_k
      @six_k ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred for legal services'))
    end

    def six_l
      @six_l ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred for housing supports (include housing supports provided with no-EOHHS funding including housing search)'))
    end

    def six_m
      @six_m ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred to Benefits providers (SNAP, SSI, WIC, etc.)'))
    end

    def six_n
      @six_n ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred to health insurance providers'))
    end

    def six_o
      @six_o ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred to other state agencies (DMH, DDS, etc.)'))
    end

    def six_p
      @six_p ||= get_client_ids(section_6_referral_scope.
          where(referred_to: 'Referred to cultural / recreational activities'))
    end

    def six_q
      @six_q ||= {}
      available_types = GrdaWarehouse::Youth::YouthReferral.new.available_referrals -
          [ 'Referred to other services / activities not listed above', 'Other' ]
      groups = section_6_referral_scope.pluck(:referred_to, :client_id).group_by(&:first)
      groups.each do |group, items|
        next if available_types.include?(group)
        @six_q[group]  = items.map{ | item | item.last }
      end
      @six_q
    end

    def total_served
      @total_served = (@four_a + @five_a + @six_a).uniq
    end

    # F. Demographics

    def demographics_scope
      GrdaWarehouse::YouthIntake::Base.
          open_between(start_date: @start_date, end_date: @end_date)
    end

    def f_one_a
      at = GrdaWarehouse::YouthIntake::Base.arel_table
      @f_one_a ||= get_client_ids(demographics_scope.
        where(at[:client_dob].gteq(@start_date - 18.years)))
    end

    def f_one_b
      @f_one_b ||= get_client_ids(demographics_scope.
        where(client_gender: 1)) # HUD.gender male
    end

    def f_one_c
      @f_one_c ||= get_client_ids(demographics_scope.
          where(client_gender: 0)) # HUD.gender female
    end

    def f_one_d
      @f_one_d ||= get_client_ids(demographics_scope.
          where(client_gender: [2, 3])) # HUD.gender trans
    end

    def f_one_e
      @f_one_e ||= get_client_ids(demographics_scope.
          where(client_gender: 4)) # HUD.gender non-binary
    end

    def f_two_a
      @f_two_a ||= get_client_ids(demographics_scope.
          where('client_race ?| array[:race]', race: 'White' ))
    end

    def f_two_b
      @f_two_b ||= get_client_ids(demographics_scope.
          where('client_race ?| array[:race]', race: 'BlackAfAmerican' ))
    end

    def f_two_c
      @f_two_c ||= get_client_ids(demographics_scope.
          where('client_race ?| array[:race]', race: 'Asian' ))
    end

    def f_two_d
      @f_two_d ||= get_client_ids(demographics_scope.
          where('client_race ?| array[:race]', race: 'AmIndAKNative' ))
    end

    def f_two_e
      @f_two_e ||= get_client_ids(demographics_scope.
          where('client_race ?| array[:race]', race: ['NativeHIOtherPacific', 'RaceNone']))
    end

    def f_two_f
      @f_two_f ||= get_client_ids(demographics_scope.
          where(client_ethnicity: 1)) # HUD.ethnicity Hispanic/Latino
    end

    def f_two_g
      @f_two_g ||= get_client_ids(demographics_scope.
        where(client_primary_language: 'English'))
    end

    def f_two_h
      @f_two_h ||= get_client_ids(demographics_scope.
          where(client_primary_language: 'Spanish'))
    end

    def f_two_i
      @f_two_i ||= get_client_ids(demographics_scope.
          where.not(client_primary_language: ['English', 'Spanish']))
    end

    def f_three_a
      @f_three_a ||= get_client_ids(demographics_scope.
          where(' disabilities ?| array[:disability]', disability: 'Mental / Emotional disability'))
    end

    def f_three_b
      @f_three_b ||= get_client_ids(demographics_scope.
          where(' disabilities ?| array[:disability]', disability: 'Medical / Physical disability'))
    end

    def f_three_c
      @f_three_c ||= get_client_ids(demographics_scope.
          where(' disabilities ?| array[:disability]', disability: 'Developmental disability'))
    end

    def f_four_a
      @f_four_a ||= get_client_ids(demographics_scope.
          where(pregnant_or_parenting: ['Pregnant', 'Parenting', 'Pregnant and Parenting']))
    end

    def f_four_b
      @f_four_b ||= get_client_ids(demographics_scope.
          where(client_lgbtq: 'Yes'))
    end

    def f_four_c
      @f_four_c ||= get_client_ids(demographics_scope.
          where(secondary_education: ['Completed High School', 'Completed GED/HiSET']))
    end

    def f_four_d
      @f_four_d ||= get_client_ids(demographics_scope.
          where(secondary_education: 'Currently attending High School'))
    end

    def f_four_e
      @f_four_e ||= get_client_ids(demographics_scope.
          where(attending_college: 'Yes'))
    end

    def f_four_f
      @f_four_f ||= get_client_ids(demographics_scope.
        where(other_agency_involvement: 'Yes'))
    end

    def f_four_g
      @f_four_g ||= get_client_ids(demographics_scope.
          where(health_insurance: 'Yes'))
    end

    def f_four_h
      @f_four_h ||= get_client_ids(demographics_scope.
          where(owns_cell_phone: 'Yes'))
    end

    private def get_client_ids(scope)
      scope.distinct.pluck(:client_id)
    end

    private def homeless_statuses
      @homeless_statuses ||=
        [
          'Experiencing homelessness: couch surfing',
          'Experiencing homelessness: street',
          'Experiencing homelessness: in shelter',
        ]
    end

  end
end