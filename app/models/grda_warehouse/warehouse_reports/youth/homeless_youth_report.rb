###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Youth
  class HomelessYouthReport
    include ArelHelper

    def initialize(filter)
      @start_date = filter.start
      @end_date = filter.end
    end

    def all_open_intakes
      open_during_report_range
    end

    def open_during_report_range
      GrdaWarehouse::YouthIntake::Base.
        open_between(start_date: @start_date, end_date: @end_date)
    end

    def served_during_report_range
      open_during_report_range.served
    end

    def started_after_report_start
      served_during_report_range.opened_after(@start_date)
    end

    # A. Core Services
    private def street_outreach_intake_scope
      started_after_report_start.street_outreach_initial_contact
    end

    private def non_street_outreach_intake_scope
      started_after_report_start.non_street_outreach_initial_contact
    end

    private def new_intake_during_report_range_some_indication_of_at_risk
      @new_intake_during_report_range_some_indication_of_at_risk ||= begin
        ids_from_intakes = open_during_report_range.
          opened_after(@start_date).
          at_risk.pluck(:client_id)
        ids_from_case_notes = open_during_report_range.
          opened_after(@start_date).joins(:case_managements).
          merge(with_case_note_in_range.at_risk).
          pluck(:client_id)
        open_during_report_range.opened_after(@start_date).
          where(client_id: ids_from_intakes + ids_from_case_notes)
      end
    end

    private def at_risk_case_management_during_range
      with_case_note_in_range.at_risk
    end

    private def new_intake_during_report_range_some_indication_of_homeless
      @new_intake_during_report_range_some_indication_of_homeless ||= begin
        ids_from_intakes = open_during_report_range.
          opened_after(@start_date).
          homeless.pluck(:client_id)
        ids_from_case_notes = open_during_report_range.
          opened_after(@start_date).joins(:case_managements).
          merge(
            with_case_note_in_range.homeless,
          ).pluck(:client_id)
        open_during_report_range.opened_after(@start_date).
          where(client_id: ids_from_intakes + ids_from_case_notes)
      end
    end

    private def new_intake_during_report_range_stably_housed
      @new_intake_during_report_range_stably_housed ||= begin
        ids_from_intakes = open_during_report_range.
          opened_after(@start_date).
          pluck(:client_id)
        ids_from_case_notes = open_during_report_range.
          opened_after(@start_date).joins(:case_managements).
          merge(
            with_case_note_in_range,
          ).pluck(:client_id)
        at_risk_client_ids = new_intake_during_report_range_some_indication_of_at_risk.pluck(:client_id)
        homeless_client_ids = new_intake_during_report_range_some_indication_of_homeless.pluck(:client_id)
        open_during_report_range.opened_after(@start_date).
          where(client_id: ids_from_intakes + ids_from_case_notes).
          where.not(client_id: at_risk_client_ids + homeless_client_ids)
      end
    end

    private def stably_housed_case_management_during_range
      at_risk_case_notes = at_risk_case_management_during_range.pluck(:client_id)
      homeless_case_notes = homeless_case_management_during_range.pluck(:client_id)
      with_case_note_in_range.
        where.not(client_id: at_risk_case_notes + homeless_case_notes)
    end

    private def transitioned_to_stabilized_housing_scope
      GrdaWarehouse::Youth::YouthFollowUp.
        initial_action_housed.
        where(action_on: (@start_date..@end_date))
    end

    private def with_case_note_in_range
      GrdaWarehouse::Youth::YouthCaseManagement.
        between(start_date: @start_date, end_date: @end_date)
    end

    private def homeless_case_management_during_range
      with_case_note_in_range.homeless
    end

    private def received_flex_funds_scope
      GrdaWarehouse::Youth::DirectFinancialAssistance.
        between(start_date: @start_date, end_date: @end_date)
    end

    def one_a
      @one_a ||= get_client_ids(street_outreach_intake_scope.homeless)
    end

    def one_b
      @one_b ||= get_client_ids(street_outreach_intake_scope.at_risk)
    end

    def two_a
      @two_a ||= get_client_ids(non_street_outreach_intake_scope.homeless)
    end

    def two_b
      @two_b ||= get_client_ids(non_street_outreach_intake_scope.at_risk)
    end

    def two_c
      @two_c ||= {}.tap do |result|
        groups = non_street_outreach_intake_scope.pluck(:how_hear, :client_id).group_by(&:first)
        groups.each do |group, items|
          result[group] = items.map(&:last)
        end
      end
    end

    def three_a
      @three_a ||= get_client_ids(
        new_intake_during_report_range_some_indication_of_at_risk.
        served,
      )
    end

    # Ongoing case management indicating at_risk, not newly opened
    def three_b
      @three_b ||= get_client_ids(at_risk_case_management_during_range) - three_a
    end

    def three_c
      @three_c ||= get_client_ids(
        new_intake_during_report_range_some_indication_of_at_risk.
        not_served,
      )
    end

    def four_a
      @four_a ||= get_client_ids(
        new_intake_during_report_range_some_indication_of_homeless.
        served,
      )
    end

    # Ongoing case management indicating homeless, not newly opened
    def four_b
      @four_b ||= get_client_ids(homeless_case_management_during_range) - four_a
    end

    def four_c
      @four_c ||= get_client_ids(
        new_intake_during_report_range_some_indication_of_homeless.
        not_served,
      )
    end

    # Non-at-risk, Non-homeless
    def stably_housed_a
      @stably_housed_a ||= get_client_ids(new_intake_during_report_range_stably_housed.served)
    end

    def stably_housed_b
      @stably_housed_b ||= get_client_ids(stably_housed_case_management_during_range) - stably_housed_a
    end


    def five_a
      @five_a ||= get_client_ids(received_flex_funds_scope)
    end

    def five_b
      @five_b ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Move-in costs'))
    end

    def five_c
      @five_c ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Rent'))
    end

    def five_d
      @five_d ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Rent arrears'))
    end

    def five_e
      @five_e ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Utilities'))
    end

    def five_f
      @five_f ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Transportation-related costs'))
    end

    def five_g
      @five_g ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Education-related costs'))
    end

    def five_h
      @five_h ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Legal costs'))
    end

    def five_i
      @five_i ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Child care'))
    end

    def five_j
      @five_j ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Work-related costs'))
    end

    def five_k
      @five_k ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Medical costs'))
    end

    def five_l
      @five_l ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Cell phone costs'))
    end

    def five_m
      @five_m ||= get_client_ids(received_flex_funds_scope.
        where(type_provided: 'Food / Groceries (including our drop-in food pantries)'))
    end

    def five_n
      @five_n ||= begin
        result = {}
        report_types = GrdaWarehouse::Youth::DirectFinancialAssistance.new.report_types
        groups = received_flex_funds_scope.pluck(:type_provided, :client_id).group_by(&:first)
        groups.each do |group, items|
          next if report_types.include?(group)

          result[group] = items.map(&:last)
        end
        result
      end
    end

    def referral_in_range_scope
      GrdaWarehouse::Youth::YouthReferral.
        between(start_date: @start_date, end_date: @end_date)
    end

    def six_a
      @six_a ||= get_client_ids(referral_in_range_scope)
    end

    def six_b
      @six_b ||= get_client_ids(referral_in_range_scope.
        where(referred_to: 'Referred for health services'))
    end

    def six_c
      @six_c ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred for mental health services'))
    end

    def six_d
      @six_d ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred for substance use services'))
    end

    def six_e
      @six_e ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred for employment & job training services'))
    end

    def six_f
      @six_f ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred for education services'))
    end

    def six_g
      @six_g ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred for parenting services'))
    end

    def six_h
      @six_h ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred for domestic violence-related services'))
    end

    def six_i
      @six_i ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred for lifeskills / financial literacy services'))
    end

    def six_j
      @six_j ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred for legal services'))
    end

    def six_k
      @six_k ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred for legal services'))
    end

    def six_l
      @six_l ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred for housing supports (include housing supports provided with no-EOHHS funding including housing search)'))
    end

    def six_m
      @six_m ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred to Benefits providers (SNAP, SSI, WIC, etc.)'))
    end

    def six_n
      @six_n ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred to health insurance providers'))
    end

    def six_o
      @six_o ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred to other state agencies (DMH, DDS, etc.)'))
    end

    def six_p
      @six_p ||= get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred to cultural / recreational activities'))
    end

    def six_q
      @six_q ||= begin
        result = {}
        available_types = GrdaWarehouse::Youth::YouthReferral.new.available_referrals -
            [ 'Referred to other services / activities not listed above', 'Other' ]
        groups = referral_in_range_scope.pluck(:referred_to, :client_id).group_by(&:first)
        groups.each do |group, items|
          next if available_types.include?(group)

          result[group] = items.map(&:last)
        end
        result
      end
    end

    def client_ids_for_opened_intakes
      get_client_ids(all_open_intakes.served.opened_after(@start_date))
    end

    def client_ids_for_open_intakes
      get_client_ids(all_open_intakes.served)
    end

    def client_ids_for_case_notes_in_range
      get_client_ids(with_case_note_in_range)
    end

    def all_served
      all_open_intakes.served.open_between(start_date: @start_date, end_date: @end_date).
        where(client_id: total_client_ids_served)
    end

    # Clients with a new intake, or a case note, financial assistance, or referral within the date range
    def total_client_ids_served
      @total_client_ids_served ||= (client_ids_for_opened_intakes + client_ids_for_case_notes_in_range + five_a + six_a).uniq
    end

    # C. College Student Services
    def college_scope
      all_served
    end

    def c_one_college_pilot
      @c_one_college_pilot ||= get_client_ids(college_scope.
        where(college_pilot: 'Yes'))
    end

    def c_three_college_non_pilot
      @c_three_college_non_pilot ||= get_client_ids(college_scope.
        where(college_pilot: 'No', attending_college: 'Yes'))
    end

    def total_college
      @total_college ||= (c_one_college_pilot + c_three_college_non_pilot).uniq
    end

    # F. Demographics
    def f_one_a
      at = GrdaWarehouse::YouthIntake::Base.arel_table
      @f_one_a ||= get_client_ids(all_served.
        where(at[:client_dob].gteq(@start_date - 18.years)))
    end

    def f_one_b
      @f_one_b ||= get_client_ids(all_served.
        where(client_gender: 1)) # HUD.gender male
    end

    def f_one_c
      @f_one_c ||= get_client_ids(all_served.
          where(client_gender: 0)) # HUD.gender female
    end

    def f_one_d
      @f_one_d ||= get_client_ids(all_served.
          where(client_gender: [2, 3])) # HUD.gender trans
    end

    def f_one_e
      @f_one_e ||= get_client_ids(all_served.
          where(client_gender: 4)) # HUD.gender non-binary
    end

    def f_two_a
      @f_two_a ||= get_client_ids(all_served.
          where('client_race ?| array[:race]', race: 'White' ))
    end

    def f_two_b
      @f_two_b ||= get_client_ids(all_served.
          where('client_race ?| array[:race]', race: 'BlackAfAmerican' ))
    end

    def f_two_c
      @f_two_c ||= get_client_ids(all_served.
          where('client_race ?| array[:race]', race: 'Asian' ))
    end

    def f_two_d
      @f_two_d ||= get_client_ids(all_served.
          where('client_race ?| array[:race]', race: 'AmIndAKNative' ))
    end

    def f_two_e
      TodoOrDie('When we update reporting for 2022 spec', by: '2021-10-01')
      @f_two_e ||= get_client_ids(all_served.
        where('client_race ?| array[:race]', race: ['NativeHIOtherPacific', 'RaceNone']))
    end

    def f_two_f
      @f_two_f ||= get_client_ids(all_served.
          where(client_ethnicity: 1)) # HUD.ethnicity Hispanic/Latino
    end

    def f_two_g
      @f_two_g ||= get_client_ids(all_served.
        where(client_primary_language: 'English'))
    end

    def f_two_h
      @f_two_h ||= get_client_ids(all_served.
          where(client_primary_language: 'Spanish'))
    end

    def f_two_i
      @f_two_i ||= get_client_ids(all_served.
          where.not(client_primary_language: ['English', 'Spanish', 'Unknown']))
    end

    def f_three_a
      @f_three_a ||= get_client_ids(all_served.
        where('lower( disabilities::text )::jsonb ?| array[:disability]', disability: 'mental / emotional disability'))
    end

    def f_three_b
      @f_three_b ||= get_client_ids(all_served.
        where('lower( disabilities::text )::jsonb ?| array[:disability]', disability: 'medical / physical disability'))
    end

    def f_three_c
      @f_three_c ||= get_client_ids(all_served.
        where('lower( disabilities::text )::jsonb ?| array[:disability]', disability: 'developmental disability'))
    end

    def f_four_a
      @f_four_a ||= get_client_ids(all_served.
          where(pregnant_or_parenting: ['Pregnant', 'Parenting', 'Pregnant and Parenting']))
    end

    def f_four_b
      @f_four_b ||= get_client_ids(all_served.
          where(client_lgbtq: 'Yes'))
    end

    def f_four_c
      @f_four_c ||= get_client_ids(all_served.
        where(secondary_education: ['Completed High School', 'Completed GED/HiSET']))
    end

    def f_four_d
      @f_four_d ||= get_client_ids(all_served.
          where(secondary_education: 'Currently attending High School'))
    end

    def f_four_e
      @f_four_e ||= get_client_ids(all_served.
          where(attending_college: 'Yes'))
    end

    def f_four_f
      @f_four_f ||= get_client_ids(
        all_served.
        where(Arel.sql("not other_agency_involvements::jsonb ?| array['No', 'Unknown'] and other_agency_involvements::jsonb != '[]'")),
      )
    end

    def f_four_g
      @f_four_g ||= get_client_ids(all_served.
          where(health_insurance: 'Yes'))
    end

    def f_four_h
      @f_four_h ||= get_client_ids(all_served.
          where(owns_cell_phone: 'Yes'))
    end

    # Follow Ups

    def follow_occured_during_range
      GrdaWarehouse::Youth::YouthFollowUp.
        between(start_date: @start_date, end_date: @end_date)
    end

    def follow_up_from_at_risk
      follow_occured_during_range.initial_action_at_risk
    end

    def follow_up_one_a
      @follow_up_one_a ||= get_client_ids(follow_up_from_at_risk)
    end

    def follow_up_one_b
      @follow_up_one_b ||= get_client_ids(follow_up_from_at_risk.
        where(housing_status: [:at_risk, :housed]))
    end

    def follow_up_from_homelessness
      follow_occured_during_range.initial_action_housed
    end

    def follow_up_two_a
      @follow_up_two_a ||= get_client_ids(transitioned_to_stabilized_housing_scope)
    end

    def follow_up_two_b
      @follow_up_two_b ||= get_client_ids(follow_up_from_homelessness)
    end

    def follow_up_two_c
      @follow_up_two_c ||= get_client_ids(follow_up_from_homelessness.
        where(housing_status: :housed))
    end

    def follow_up_two_d
      @follow_up_two_d ||= follow_up_from_homelessness.pluck(:zip_code).uniq
    end

    def g_one_a
      at = GrdaWarehouse::YouthIntake::Base.arel_table
      @g_one_a ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
        where(at[:client_dob].gteq(@start_date - 18.years)))
    end

    def g_one_b
      @g_one_b ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
        where(client_gender: 1)) # HUD.gender male
    end

    def g_one_c
      @g_one_c ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where(client_gender: 0)) # HUD.gender female
    end

    def g_one_d
      @g_one_d ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where(client_gender: [2, 3])) # HUD.gender trans
    end

    def g_one_e
      @g_one_e ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where(client_gender: 4)) # HUD.gender non-binary
    end

    def g_two_a
      @g_two_a ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race]', race: 'White' ))
    end

    def g_two_b
      @g_two_b ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race]', race: 'BlackAfAmerican' ))
    end

    def g_two_c
      @g_two_c ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race]', race: 'Asian' ))
    end

    def g_two_d
      @g_two_d ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race]', race: 'AmIndAKNative' ))
    end

    def g_two_e
      TodoOrDie('When we update reporting for 2022 spec', by: '2021-10-01')
      @g_two_e ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race]', race: ['NativeHIOtherPacific', 'RaceNone']))
    end

    def g_two_f
      @g_two_f ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where(client_ethnicity: 1)) # HUD.ethnicity Hispanic/Latino
    end

    def g_three_b
      @g_three_b ||= get_client_ids(all_served.
        joins(:youth_follow_ups).
        merge(transitioned_to_stabilized_housing_scope).
        where(client_lgbtq: 1))
    end

    def h_one_a
      at = GrdaWarehouse::YouthIntake::Base.arel_table
      @h_one_a ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(follow_up_from_at_risk).
        where(at[:client_dob].gteq(@start_date - 18.years)))
    end

    def h_one_b
      @h_one_b ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(follow_up_from_at_risk).
        where(client_gender: 1)) # HUD.gender male
    end

    def h_one_c
      @h_one_c ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(follow_up_from_at_risk).
          where(client_gender: 0)) # HUD.gender female
    end

    def h_one_d
      @h_one_d ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(follow_up_from_at_risk).
          where(client_gender: [2, 3])) # HUD.gender trans
    end

    def h_one_e
      @h_one_e ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(follow_up_from_at_risk).
          where(client_gender: 4)) # HUD.gender non-binary
    end

    def h_two_a
      @h_two_a ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(follow_up_from_at_risk).
          where('client_race ?| array[:race]', race: 'White' ))
    end

    def h_two_b
      @h_two_b ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(follow_up_from_at_risk).
          where('client_race ?| array[:race]', race: 'BlackAfAmerican' ))
    end

    def h_two_c
      @h_two_c ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(follow_up_from_at_risk).
          where('client_race ?| array[:race]', race: 'Asian' ))
    end

    def h_two_d
      @h_two_d ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(follow_up_from_at_risk).
          where('client_race ?| array[:race]', race: 'AmIndAKNative' ))
    end

    def h_two_e
      TodoOrDie('When we update reporting for 2022 spec', by: '2021-10-01')
      @h_two_e ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(follow_up_from_at_risk).
          where('client_race ?| array[:race]', race: ['NativeHIOtherPacific', 'RaceNone']))
    end

    def h_two_f
      @h_two_f ||= get_client_ids(all_served.
        joins(:youth_follow_ups).merge(follow_up_from_at_risk).
          where(client_ethnicity: 1)) # HUD.ethnicity Hispanic/Latino
    end

    def h_three_b
      @h_three_b ||= get_client_ids(all_served.
        joins(:youth_follow_ups).
        merge(follow_up_from_at_risk).
          where(client_lgbtq: 1))
    end

    # def follow_up_two_d
    #   @follow_up_two_d ||= begin
    #     result = {}
    #     follow_up_housing.values.each { |value| result[value] = [] }
    #     groups = follow_up_from_homelessness.pluck(:housing_status, :client_id).group_by(&:first)
    #     groups.each do |group, items|
    #       next if group == 'No'
    #       key = follow_up_housing[group]
    #       result[key]  = items.map{ | item | item.last }
    #     end
    #     result
    #   end
    # end

    def allowed_report_keys
      @allowed_report_keys ||= [
        :one_a,
        :one_b,
        :two_a,
        :two_b,
        :two_c,
        :three_a,
        :three_b,
        :three_c,
        :four_a,
        :four_b,
        :four_c,
        :four_d,
        :stably_housed_a,
        :stably_housed_b,
        :five_a,
        :five_b,
        :five_c,
        :five_d,
        :five_e,
        :five_f,
        :five_g,
        :five_h,
        :five_i,
        :five_j,
        :five_k,
        :five_l,
        :five_m,
        :five_n,
        :five_o,
        :six_a,
        :six_b,
        :six_c,
        :six_d,
        :six_e,
        :six_f,
        :six_g,
        :six_h,
        :six_i,
        :six_j,
        :six_k,
        :six_l,
        :six_m,
        :six_n,
        :six_o,
        :six_p,
        :six_q,
        :total_client_ids_served,
        :total_served,
        :c_one_college_pilot,
        :c_two_graduating_college_pilot,
        :c_three_college_non_pilot,
        :total_college,
        :all_open_intakes,
        :f_one_a,
        :f_one_b,
        :f_one_c,
        :f_one_d,
        :f_one_e,
        :f_two_a,
        :f_two_b,
        :f_two_c,
        :f_two_d,
        :f_two_e,
        :f_two_f,
        :f_two_g,
        :f_two_h,
        :f_two_i,
        :f_three_a,
        :f_three_b,
        :f_three_c,
        :f_four_a,
        :f_four_b,
        :f_four_c,
        :f_four_d,
        :f_four_e,
        :f_four_f,
        :f_four_g,
        :f_four_h,
        :follow_up_one_a,
        :follow_up_one_b,
        :follow_up_two_a,
        :follow_up_two_b,
        :follow_up_two_c,
        :follow_up_two_d,
        :g_one_a,
        :g_one_b,
        :g_one_c,
        :g_one_d,
        :g_one_e,
        :g_two_a,
        :g_two_b,
        :g_two_c,
        :g_two_d,
        :g_two_e,
        :g_two_f,
        :g_three_b,
        :h_one_a,
        :h_one_b,
        :h_one_c,
        :h_one_d,
        :h_one_e,
        :h_two_a,
        :h_two_b,
        :h_two_c,
        :h_two_d,
        :h_two_e,
        :h_two_f,
        :h_three_b,
        :client_ids_for_open_intakes,
      ]
    end

    private def get_client_ids(scope)
      scope.distinct.pluck(:client_id)
    end

    private def follow_up_housing
      {
        'Yes, in RRH' => 'RRH',
        'Yes, in market-rate housing' => 'Market-Rate',
        'Yes, in transitional housing'=> 'Transitional',
        'Yes, with family' => 'Family',
      }
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
