###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Provides household-level logic for HUD report generators (FY2021–FY2025).
#
# This concern operates in two distinct phases:
#
# 1. Universe build phase: `calculate_households` builds `@households`, an in-memory hash of
#    enrollment snapshot data keyed by household_id. Methods like `household_chronic_status`,
#    `household_makeup`, and `calculate_move_in_date` query this hash to populate universe records.
#
# 2. Question answer phase: after snapshot models are persisted, methods like `household_adults`,
#    `only_youth?`, and `youth_parent?` operate on the snapshot model's `household_members` JSON
#    column (present on some snapshot types, e.g. AprClient) — not on `@households`.
#
# In FY2026+, this concern is largely superseded by HouseholdContextBuilder + HouseholdLogic,
# which pre-compute all household attributes into HouseholdContext records before report generation.
# Do not add new functionality here — new household logic belongs in HouseholdLogic, and new
# report generators should use the HouseholdContext layer instead of this concern.
#
# Required concerns:  HudReports::Ages
# Required accessors: a_t, enrollment_scope, client_scope
# Required universe fields: household_type, head_of_household, head_of_household_id
module HudReports::Households
  extend ActiveSupport::Concern

  included do
    private def batch_size
      250
    end

    private def hoh_clause
      a_t[:head_of_household].eq(true)
    end

    private def hoh_or_spouse
      a_t[:relationship_to_hoh].in([1, 3])
    end

    private def adult_or_hoh_clause
      adult_clause.or(hoh_clause)
    end

    private def ages_for(household_id, date)
      return [] unless households[household_id]

      households[household_id].map { |client| GrdaWarehouse::Hud::Client.age(date: date, dob: client[:dob]) }
    end

    def household_members_for(household_id)
      households[household_id] || []
    end

    def hoh_age(household_id, date)
      return unless households[household_id]

      hoh_dob = households[household_id].detect { |hm| hm[:relationship_to_hoh] == 1 }&.try(:[], :dob)
      return unless hoh_dob

      GrdaWarehouse::Hud::Client.age(date: date, dob: hoh_dob)
    end

    private def hoh_exit_date(household_id)
      return unless households[household_id]

      households[household_id].detect { |hm| hm[:relationship_to_hoh] == 1 }&.try(:[], :exit_date)
    end

    private def get_hh_id(service_history_enrollment)
      service_history_enrollment.household_id || "#{service_history_enrollment.enrollment_group_id}*HH"
    end

    private def households
      calculate_households if @households.nil?
      @households
    end

    private def hoh_enrollments
      calculate_households if @hoh_enrollments.nil?
      @hoh_enrollments
    end

    # CH at Project Start (chronic_status): any household member present at start can cause the household to be CH.
    # CH at Point in Time (pit_chronic_status): at least one adult or minor head of household must be CH.
    # If no qualifying members are CH, use self for adults, and the HoH enrollment for children.
    # from glossary:
    # In cases where the head of household as well as all other adult household members have an indeterminate CH status (don’t know, refused, missing), any child household members should carry the same CH status as the head of household.
    # NOTE: Client CH status is only inherited if the client was present at the start of the enrollment.
    # per HUD guidance, the HoH should always be present for the entire stay, so we'll compare start dates to them
    # see AirTable Issue ID 30
    private def calculate_household_chronic_status(hh_id, client_id, chronic_status_key: :chronic_status)
      household_members = households[hh_id]
      return false unless household_members.present?

      hoh = household_members.detect { |hm| hm[:relationship_to_hoh] == 1 }
      current_member = household_members.detect { |hm| hm[:client_id] == client_id } || hoh

      HudReports::HouseholdLogic.calculate_chronic_status(
        household_members,
        current_member,
        hoh,
        chronic_status_key: chronic_status_key,
      )
    end

    private def household_chronic_status(hh_id, client_id)
      result = calculate_household_chronic_status(hh_id, client_id)
      return result unless result

      { chronic_status: !!result[:status], chronic_detail: result[:detail] }.with_indifferent_access
    end

    private def pit_household_chronic_status(hh_id)
      result = calculate_household_chronic_status(hh_id, nil, chronic_status_key: :pit_chronic_status)
      return result unless result

      { pit_chronic_status: !!result[:status], pit_chronic_detail: result[:detail] }.with_indifferent_access
    end

    private def calculate_hh_move_in_date(hh_id, she)
      household_members = households[hh_id]
      return nil unless household_members.present?

      # Get HoH for further calculations
      hoh = household_members.detect { |hm| hm[:relationship_to_hoh] == 1 }

      member_data = {
        entry_date: she.entry_date,
        exit_date: she.exit_date,
        move_in_date: she.move_in_date,
      }

      HudReports::HouseholdLogic.calculate_move_in_date(member_data, hoh, report_end_date: @report.end_date)
    end

    # Two-step: use the member's own move-in date if it's valid (on or after entry);
    # otherwise delegate to household inheritance rules via calculate_hh_move_in_date.
    private def calculate_move_in_date(hh_id, she)
      move_in_date = she.move_in_date
      return move_in_date if move_in_date.present? && move_in_date >= she.entry_date

      calculate_hh_move_in_date(hh_id, she)
    end

    private def calculate_households
      @hoh_enrollments ||= {}
      @households ||= {}

      # NOTE: batch_size must match calculate_households in the class that includes this concern
      @generator.client_scope.find_in_batches(batch_size: batch_size) do |batch|
        enrollments_by_client_id = clients_with_enrollments(
          batch,
          scope: enrollment_scope_without_preloads,
          preloads: { enrollment: [:client, :disabilities_at_entry, :project] },
        )
        enrollments_by_client_id.each do |_, enrollments|
          enrollments.each do |enrollment|
            @hoh_enrollments[enrollment.household_id] = enrollment if enrollment.head_of_household?
            next unless enrollment&.enrollment&.client.present?

            date = [enrollment.first_date_in_program, @report.start_date].max
            age = GrdaWarehouse::Hud::Client.age(date: date, dob: enrollment.enrollment.client.DOB&.to_date)
            # PIT reports supply a specific `on` date; for non-PIT reports fall back to entry date
            # so pit_chronic_status is computed relative to the correct reference point.
            report_date = @generator.filter&.on if @generator.respond_to?(:filter) && @generator.filter.present?
            report_date ||= enrollment.enrollment.EntryDate

            @households[get_hh_id(enrollment)] ||= []
            @households[get_hh_id(enrollment)] << {
              client_id: enrollment.client_id,
              source_client_id: enrollment.enrollment.client.id,
              dob: enrollment.enrollment.client.DOB,
              age: age,
              veteran_status: enrollment.enrollment.client.VeteranStatus,
              # Chronic status is calculated as of the report date, use the enrollment start date if no report date is provided
              pit_chronic_status: enrollment.enrollment.chronically_homeless_at_start?(date: report_date),
              pit_chronic_detail: enrollment.enrollment.chronically_homeless_at_start(date: report_date),
              # Chronic status is calculated as of the enrollment start date
              chronic_status: enrollment.enrollment.chronically_homeless_at_start?,
              chronic_detail: enrollment.enrollment.chronically_homeless_at_start,
              relationship_to_hoh: enrollment.enrollment.RelationshipToHoH,
              # Include dates for determining if someone was present at assessment date
              entry_date: enrollment.first_date_in_program,
              exit_date: enrollment.last_date_in_program,
              move_in_date: enrollment.move_in_date,
            }.with_indifferent_access
          end
        end
        GC.start # release enrollment objects between batches; this loop can hold significant memory
      end
    end

    private def get_hoh_id(hh_id)
      households[hh_id]&.detect { |household| household[:relationship_to_hoh] == 1 }.try(:[], :client_id)
    end

    # Returns all household members for the given enrollment from the pre-built households cache.
    # The _date parameter is accepted for backward compatibility with FY2020-FY2024 generators that
    # pass a calculation date, but is intentionally ignored here. The CE APR question concern
    # overrides this method with actual date-scoped filtering. In FY2026+, date-scoped household
    # composition is handled upstream in AprClientBuilder#ce_scoped_household_members.
    private def household_member_data(enrollment, _date = nil)
      households[enrollment.household_id] || []
    end

    # --- Question answer phase ---
    # The methods below operate on the snapshot model's household_members JSON column
    # (present on some snapshot types, e.g. AprClient) rather than on the @households hash.

    private def household_adults(universe_client)
      return [] unless universe_client.household_members

      date = [universe_client.first_date_in_program, @report.start_date].max
      universe_client.household_members.select do |member|
        next false if member['dob'].blank?

        age = GrdaWarehouse::Hud::Client.age(date: date, dob: member['dob'].to_date)
        age.present? && age >= 18
      end
    end

    private def only_youth?(universe_client)
      youth_and_child_household_members(universe_client).count == universe_client.household_members.count
    end

    private def youth_and_child_household_members(universe_client)
      return [] unless universe_client.household_members

      date = [universe_client.first_date_in_program, @report.start_date].max
      universe_client.household_members&.select do |member|
        next false if member['dob'].blank?

        age = GrdaWarehouse::Hud::Client.age(date: date, dob: member['dob'].to_date)
        age.present? && age <= 24
      end
    end

    private def youth_child_members(universe_client)
      youth_and_child_household_members(universe_client).select do |member|
        member['relationship_to_hoh'] == 2
      end
    end

    private def youth_children?(universe_client)
      youth_child_members(universe_client).any?
    end

    private def youth_child_source_client_ids(universe_client)
      youth_child_members(universe_client).map { |member| member['source_client_id'] }
    end

    private def adult_source_client_ids(universe_client)
      household_adults(universe_client).map { |member| member['source_client_id'] }
    end

    # Per HUD:
    # https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recCDGtYIVXlTmAvk
    # . The glossary does not make reference to the "relationship to head of household" required to include a youth in this category. Q27b ("Parenting Youth") is a bit clearer in the following language: "Report all heads of household plus all adults (age 18 – 24) in the household in column B according to the age of the head of household (age < 18 on line 2, or 18-24 on line 3). Include all adults in the household regardless of [relationship to head of household],"
    private def youth_parent?(universe_client)
      age = universe_client.age
      adult = age.present? && age >= 18
      (universe_client.head_of_household || adult) && only_youth?(universe_client) && youth_children?(universe_client)
    end

    private def household_makeup(household_id, date)
      household_ages = ages_for(household_id, date)
      HudReports::HouseholdLogic.calculate_household_type(household_ages)
    end

    private def sub_populations
      {
        'Total' => Arel.sql('1=1'), # include everyone
        'Without Children' => a_t[:household_type].eq(:adults_only),
        'With Children and Adults' => a_t[:household_type].eq(:adults_and_children),
        'With Only Children' => a_t[:household_type].eq(:children_only),
        'Unknown Household Type' => a_t[:household_type].eq(:unknown),
      }
    end
  end
end
