###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

    def all_served_last_assessment
      all_served.only_most_recent_by_client
    end

    def all_served_ids_by_agency
      user_id_to_agency_name = User.joins(:agency).pluck(:id, Agency.arel_table[:name]).to_h
      all_served.group_by { |client| user_id_to_agency_name[client.user_id] }.
        transform_values { |clients| clients.map(&:client_id) }
    end

    # Clients with a new intake, or a case note, financial assistance, or referral within the date range
    def total_client_ids_served
      @total_client_ids_served ||= (client_ids_for_opened_intakes + client_ids_for_case_notes_in_range + five_a).uniq
    end

    # D. Demographics
    def d_one_a
      at = GrdaWarehouse::YouthIntake::Base.arel_table
      @d_one_a ||= get_client_ids(all_served_last_assessment.
        where(at[:client_dob].gteq(@start_date - 18.years)))
    end

    def d_one_b
      @d_one_b ||= get_client_ids(all_served_last_assessment.
        where(client_gender: 1)) # HudUtility.gender man
    end

    def d_one_c
      @d_one_c ||= get_client_ids(all_served_last_assessment.
          where(client_gender: 0)) # HudUtility.gender woman
    end

    def d_one_d
      @d_one_d ||= get_client_ids(all_served_last_assessment.
          where(client_gender: [2, 3])) # HudUtility.gender trans
    end

    def d_one_e
      @d_one_e ||= get_client_ids(all_served_last_assessment.
          where(client_gender: 4)) # HudUtility.gender non-binary
    end

    def d_one_f
      @d_one_f ||= get_client_ids(all_served_last_assessment.
          where(client_gender: [6, 8, 9])) # HudUtility.gender questioning, 8, 9
    end

    def d_one_g
      @d_one_g ||= get_client_ids(all_served_last_assessment.
          where(client_gender: 99)) # HudUtility.gender 99
    end

    def d_two_a
      @d_two_a ||= get_client_ids(all_served_last_assessment.
          where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'White'))
    end

    def d_two_b
      @d_two_b ||= get_client_ids(all_served_last_assessment.
          where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'BlackAfAmerican'))
    end

    def d_two_c
      @d_two_c ||= get_client_ids(all_served_last_assessment.
          where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'Asian'))
    end

    def d_two_d
      @d_two_d ||= get_client_ids(all_served_last_assessment.
          where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'AmIndAKNative'))
    end

    def d_two_e
      @d_two_e ||= get_client_ids(all_served_last_assessment.
        where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'NativeHIPacific'))
    end

    def d_two_f
      @d_two_f ||= get_client_ids(all_served_last_assessment.
        where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'MidEastNAfrican'))
    end

    def d_two_g
      @d_two_g ||= get_client_ids(all_served_last_assessment.
        where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'HispanicLatinaeo'))
    end

    def d_two_h
      @d_two_h ||= get_client_ids(all_served_last_assessment.
        where('client_race ?| array[:race] OR jsonb_array_length(client_race) > 1', race: 'RaceNone'))
    end

    def d_two_i
      @d_two_i ||= get_client_ids(all_served_last_assessment.
        where(client_primary_language: 'English'))
    end

    def d_two_j
      @d_two_j ||= get_client_ids(all_served_last_assessment.
          where(client_primary_language: 'Spanish'))
    end

    def d_two_k
      @d_two_k ||= get_client_ids(all_served_last_assessment.
          where.not(client_primary_language: ['English', 'Spanish', 'Unknown']))
    end

    def d_three_a
      @d_three_a ||= get_client_ids(all_served_last_assessment.
        where('lower( disabilities::text )::jsonb ?| array[:disability]', disability: 'mental / emotional disability'))
    end

    def d_three_b
      # Include clients who do not have this recorded as a disability, but do have a referral
      @d_three_b ||= (
        get_client_ids(all_served_last_assessment.
        where('lower( disabilities::text )::jsonb ?| array[:disability]', disability: 'substance abuse disorder')) +
        get_client_ids(referral_in_range_scope.
          where(referred_to: 'Referred for substance use services'))
      ).uniq
    end

    def d_three_c
      @d_three_c ||= get_client_ids(all_served_last_assessment.
        where('lower( disabilities::text )::jsonb ?| array[:disability]', disability: 'medical / physical disability'))
    end

    def d_three_d
      @d_three_d ||= get_client_ids(all_served_last_assessment.
        where('lower( disabilities::text )::jsonb ?| array[:disability]', disability: 'developmental disability'))
    end

    def d_four_a
      @d_four_a ||= get_client_ids(all_served_last_assessment.
          where(pregnant_or_parenting: ['Pregnant', 'Parenting', 'Pregnant and Parenting']))
    end

    def d_four_b
      @d_four_b ||= get_client_ids(all_served_last_assessment.
          where(client_lgbtq: 'Yes'))
    end

    def d_four_c
      @d_four_c ||= get_client_ids(all_served_last_assessment.
        where(secondary_education: ['Completed High School', 'Completed GED/HiSET']))
    end

    def d_four_d
      @d_four_d ||= get_client_ids(all_served_last_assessment.
          where(secondary_education: 'Currently attending High School'))
    end

    def d_four_e
      @d_four_e ||= get_client_ids(all_served_last_assessment.
          where(attending_college: 'Yes'))
    end

    def d_four_g
      @d_four_g ||= get_client_ids(all_served_last_assessment.
          where(health_insurance: 'Yes'))
    end

    def d_four_h
      @d_four_h ||= get_client_ids(all_served_last_assessment.
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
      @follow_up_two_d ||= begin
        hmis_clients = GrdaWarehouse::HmisClient.where(client_id: get_source_client_ids(follow_up_from_homelessness))
        hmis_zips = hmis_clients.all.map { |hmis_client| hmis_client.processed_fields&.dig('youth_current_zip') }.compact

        follow_up_zips = follow_up_from_homelessness.pluck(:zip_code)

        (hmis_zips + follow_up_zips).uniq
      end
    end

    def g_one_a
      at = GrdaWarehouse::YouthIntake::Base.arel_table
      @g_one_a ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
        where(at[:client_dob].gteq(@start_date - 18.years)))
    end

    def g_one_b
      @g_one_b ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
        where(client_gender: 1)) # HudUtility.gender man
    end

    def g_one_c
      @g_one_c ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where(client_gender: 0)) # HudUtility.gender woman
    end

    def g_one_d
      @g_one_d ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where(client_gender: [2, 3])) # HudUtility.gender trans
    end

    def g_one_e
      @g_one_e ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where(client_gender: 4)) # HudUtility.gender non-binary
    end

    def g_one_f
      @g_one_f ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where(client_gender: [6, 8, 9])) # HudUtility.gender questioning, 8, 9
    end

    def g_one_g
      @g_one_g ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where(client_gender: 99)) # HudUtility.gender 99
    end

    def g_two_a
      @g_two_a ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'White'))
    end

    def g_two_b
      @g_two_b ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'BlackAfAmerican'))
    end

    def g_two_c
      @g_two_c ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'Asian'))
    end

    def g_two_d
      @g_two_d ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'AmIndAKNative'))
    end

    def g_two_e
      @g_two_e ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'NativeHIPacific'))
    end

    def g_two_f
      @g_two_f ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'MidEastNAfrican'))
    end

    def g_two_g
      @g_two_g ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race] AND jsonb_array_length(client_race) = 1', race: 'HispanicLatinaeo'))
    end

    def g_two_h
      @g_two_h ||= get_client_ids(all_served_last_assessment.
        joins(:youth_follow_ups).merge(transitioned_to_stabilized_housing_scope).
          where('client_race ?| array[:race] OR jsonb_array_length(client_race) > 1', race: 'RaceNone'))
    end

    def g_three_b
      @g_three_b ||= get_client_ids(all_served_last_assessment.
        only_most_recent_by_client.
        joins(:youth_follow_ups).
        merge(transitioned_to_stabilized_housing_scope).
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
        :three_a,
        :three_b,
        :four_a,
        :four_b,
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
        :total_client_ids_served,
        :total_served,
        :all_open_intakes,
        :d_one_a,
        :d_one_b,
        :d_one_c,
        :d_one_d,
        :d_one_e,
        :d_one_f,
        :d_one_g,
        :d_two_a,
        :d_two_b,
        :d_two_c,
        :d_two_d,
        :d_two_e,
        :d_two_f,
        :d_two_g,
        :d_two_h,
        :d_two_i,
        :d_two_j,
        :d_two_k,
        :d_three_a,
        :d_three_b,
        :d_three_c,
        :d_four_a,
        :d_four_b,
        :d_four_c,
        :d_four_d,
        :d_four_e,
        :d_four_g,
        :d_four_h,
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
        :g_one_f,
        :g_one_g,
        :g_two_a,
        :g_two_b,
        :g_two_c,
        :g_two_d,
        :g_two_e,
        :g_two_f,
        :g_two_g,
        :g_two_h,
        :g_three_b,
        :client_ids_for_open_intakes,
      ]
    end

    private def get_client_ids(scope)
      scope.distinct.pluck(:client_id)
    end

    private def get_source_client_ids(scope)
      GrdaWarehouse::WarehouseClient.
        joins(:source).
        where(destination_id: get_client_ids(scope)).
        pluck(:source_id)
    end

    private def follow_up_housing
      {
        'Yes, in RRH' => 'RRH',
        'Yes, in market-rate housing' => 'Market-Rate',
        'Yes, in transitional housing' => 'Transitional',
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
