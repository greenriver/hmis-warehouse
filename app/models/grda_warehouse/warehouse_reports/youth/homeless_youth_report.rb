module GrdaWarehouse::WarehouseReports::Youth
  class HomelessYouthReport

    def initialize(filter)
      @start_date = filter.start
      @end_date = filter.end
    end

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
      @three_c ||= nil # TODO
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
      @four_d ||= nil # TODO
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
      available_types = GrdaWarehouse::Youth::YouthReferral.new.available_types -
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