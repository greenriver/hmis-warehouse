# frozen_string_literal: true

module HudReports
  class HouseholdContextBuilder
    def self.call(...)
      new(...).call
    end

    def initialize(generator, report, enrollment_scope:, source_report_id: nil, lookback_years: 2)
      @generator = generator
      @report = report
      @source_report_id = source_report_id
      @enrollment_scope = enrollment_scope
      @lookback_years = lookback_years
    end

    def call
      # Idempotency: clear existing context for this report run
      @report.household_contexts.delete_all

      if @source_report_id.present?
        copy_contexts_from_source
      else
        build_contexts_from_scratch
      end

      # Update count on report instance
      @report.update!(household_context_count: @report.household_contexts.count)
    end

    private

    def copy_contexts_from_source
      # Validate date ranges match
      source_report = HudReports::ReportInstance.find(@source_report_id)
      unless source_report.start_date == @report.start_date &&
             source_report.end_date == @report.end_date
        raise ArgumentError, "Cannot share contexts: date ranges don't match"
      end

      enrollment_id_col = GrdaWarehouse::Hud::Enrollment.arel_table[:id]
      needed_source_enrollment_ids = enrollment_scope.joins(:enrollment).pluck(enrollment_id_col)

      HudReports::HouseholdContext.copy_subset!(
        source_report_id: @source_report_id,
        target_report_id: @report.id,
        source_enrollment_ids: needed_source_enrollment_ids,
      )
    end

    attr_reader :enrollment_scope

    def build_contexts_from_scratch
      contexts = []
      universe_ids, hh_pairs = snapshot_universe!
      hh_pairs.each_slice(batch_size) do |batch|
        # batch is array of [hh_id, data_source_id]
        all_service_history_enrollments = load_unfiltered_service_history_enrollments(batch)
        all_she_by_hh = all_service_history_enrollments.group_by { |she| [get_hh_id(she), she.data_source_id] }

        all_she_by_hh.each do |(hh_id, data_source_id), service_history_enrollments|
          household_contexts = build_contexts_for_household(
            hh_id: hh_id,
            data_source_id: data_source_id,
            service_history_enrollments: service_history_enrollments,
            universe_ids: universe_ids,
          )
          contexts.concat(household_contexts)

          # Flush per-household so a batch of large households can't exceed the import limit
          if contexts.size >= import_batch_size
            HudReports::HouseholdContext.import!(contexts)
            contexts = []
          end
        end
      end

      HudReports::HouseholdContext.import!(contexts) if contexts.any?
    end

    # Snapshots the SHE universe IDs and unique household pairs in a single short
    # REPEATABLE READ transaction so both reflect the same consistent DB state.
    # Live SHE rebuilds do not impact reports.
    # Falls back to no isolation when already in a transaction (e.g. test suite).
    def snapshot_universe!
      she_table = GrdaWarehouse::ServiceHistoryEnrollment.arel_table
      read_pair = lambda do
        [
          enrollment_scope.pluck(:id).to_set,
          enrollment_scope.distinct.
            order(hh_id_expr, she_table[:data_source_id]).
            pluck(hh_id_expr, she_table[:data_source_id]),
        ]
      end

      if GrdaWarehouseBase.connection.open_transactions > 0
        read_pair.call
      else
        GrdaWarehouseBase.transaction(isolation: :repeatable_read, &read_pair)
      end
    end

    def batch_size
      500
    end

    def import_batch_size
      2000
    end

    def get_hh_id(she)
      # If a HUD HouseholdID is missing, we use the EnrollmentID as a synthetic household ID.
      # We append '*HH' to these synthetic IDs to prevent accidental collisions with real
      # HouseholdIDs that might share the same string value within the same data source.
      she.household_id || "#{she.enrollment_group_id}*HH"
    end

    def hh_id_expr
      she_table = GrdaWarehouse::ServiceHistoryEnrollment.arel_table
      # Mirrors get_hh_id: the '*HH' suffix prevents collisions between real HouseholdIDs
      # and synthetic ones derived from EnrollmentIDs within the same data source.
      Arel::Nodes::NamedFunction.new(
        'COALESCE',
        [
          she_table[:household_id],
          Arel::Nodes::InfixOperation.new('||', she_table[:enrollment_group_id], Arel::Nodes.build_quoted('*HH')),
        ],
      )
    end

    def load_unfiltered_service_history_enrollments(batch)
      # batch is array of [hh_id, data_source_id]
      # We group by data_source_id to make queries more efficient (fewer IN clauses)
      service_history_enrollments = []
      batch.group_by(&:last).each do |ds_id, pairs|
        hh_ids = pairs.map(&:first)
        real_hh_ids = hh_ids.reject { |id| id.end_with?('*HH') }
        synthetic_eg_ids = hh_ids.select { |id| id.end_with?('*HH') }.map { |id| id.sub('*HH', '') }

        lookback_start = @report.start_date - @lookback_years.years

        scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          where(data_source_id: ds_id).
          open_between(start_date: lookback_start, end_date: @report.end_date).
          preload(enrollment: [:client, :disabilities_at_entry, :project])

        query = if real_hh_ids.any? && synthetic_eg_ids.any?
          scope.where(household_id: real_hh_ids).or(scope.where(enrollment_group_id: synthetic_eg_ids, household_id: nil))
        elsif real_hh_ids.any?
          scope.where(household_id: real_hh_ids)
        else
          scope.where(enrollment_group_id: synthetic_eg_ids, household_id: nil)
        end

        service_history_enrollments.concat(query.to_a.select { |m| m.enrollment.present? })
      end

      # For NBN projects, pre-compute which SHEs are "active" per Method 2:
      # must have a bed-night service OR an exit within the report date range.
      nbn_she_ids = service_history_enrollments.select(&:nbn?).map(&:id)
      @active_nbn_she_ids_in_batch = if nbn_she_ids.any?
        with_service = GrdaWarehouse::ServiceHistoryService.bed_night.
          service_excluding_extrapolated.
          service_within_date_range(start_date: @report.start_date, end_date: @report.end_date).
          where(service_history_enrollment_id: nbn_she_ids).
          pluck(:service_history_enrollment_id)

        with_exit = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          where(id: nbn_she_ids).
          exit_within_date_range(start_date: @report.start_date, end_date: @report.end_date).
          pluck(:id)

        (with_service + with_exit).to_set
      else
        Set.new
      end

      service_history_enrollments
    end

    def build_contexts_for_household(hh_id:, data_source_id:, service_history_enrollments:, universe_ids:)
      hh_member_hashes = precalculate_member_data(service_history_enrollments)

      # For household composition and veteran stats, only consider SHEs active during the report period.
      # Historical SHEs (from lookback) are used for inheritance but should not affect the current report's household type.
      active_hh_she_hashes = hh_member_hashes.select { |mh| mh[:is_active] }

      hoh_data = find_anchor_hoh(hh_member_hashes)
      hoh_adjusted_move_in_date = (household_logic.calculate_move_in_date(hoh_data, hoh_data, report_end_date: @report.end_date) if hoh_data)
      hoh_length_of_stay = household_logic.calculate_length_of_stay(hoh_data, report_end_date: @report.end_date)

      hh_stats = calculate_hh_stats(active_hh_she_hashes)

      # Lookback SHEs (outside universe_ids) are needed for HoH detection and inherited values above,
      # but we only persist contexts for SHEs that are part of the report universe.
      service_history_enrollments.filter_map do |m|
        next unless universe_ids.include?(m.id)

        member_hash = hh_member_hashes.detect { |mh| mh[:she_id] == m.id }
        build_context_for_member(m, member_hash, hoh_data,
                                 hh_member_hashes: hh_member_hashes,
                                 hoh_length_of_stay: hoh_length_of_stay,
                                 hoh_move_in_date: hoh_adjusted_move_in_date,
                                 hh_id: hh_id,
                                 data_source_id: data_source_id,
                                 active_hh_she_hashes: active_hh_she_hashes,
                                 hh_stats: hh_stats)
      end
    end

    def precalculate_member_data(service_history_enrollments)
      service_history_enrollments.map do |m|
        enrollment = m.enrollment
        source_client = enrollment&.client
        date = [m.first_date_in_program, @report.start_date].max
        age = GrdaWarehouse::Hud::Client.age(date: date, dob: source_client&.DOB)

        # Determine report_date for chronic calculation
        report_date = @generator.filter&.on if @generator.respond_to?(:filter) && @generator.filter.present?

        # Use the PIT date if provided (e.g. PIT reports), otherwise use entry date
        chronic_detail = if report_date.present? && report_date != enrollment&.EntryDate
          enrollment&.chronically_homeless_at_start(date: report_date)
        else
          enrollment&.chronically_homeless_at_start
        end

        {
          she_id: m.id,
          enrollment_id: enrollment&.id,
          destination_client_id: m.client_id,
          source_client_id: source_client&.id,
          personal_id: source_client&.PersonalID,
          entry_date: m.first_date_in_program,
          exit_date: m.last_date_in_program,
          age: age,
          dob: source_client&.DOB,
          chronic_status: chronic_detail == :yes,
          chronic_detail: chronic_detail,
          relationship_to_hoh: enrollment&.RelationshipToHoH,
          move_in_date: m.move_in_date,
          veteran_status: source_client&.VeteranStatus,
          enrollment_coc: enrollment&.EnrollmentCoC,
          date_to_street: enrollment&.DateToStreetESSH,
          is_active: nbn_active?(m),
        }
      end
    end

    def find_anchor_hoh(hh_member_hashes)
      # Select the "Anchor" HoH for inheritance, in priority order:
      # 1. Prefer HoH records active during the report period.
      # 2. Prefer the most recent enrollment (latest entry date).
      # 3. Prefer records with a move-in date.
      # 4. Deterministic tie-break via ID.
      hh_member_hashes.
        select { |m| m[:relationship_to_hoh] == 1 }.
        min_by do |m|
          [
            m[:is_active] ? 0 : 1, # active records first
            -(m[:entry_date] || Date.new(0)).jd, # latest entry date first (negated)
            m[:move_in_date] ? 0 : 1,                 # records with move-in first
            m[:she_id] || 0,                          # lowest ID as tie-break
          ]
        end
    end

    def calculate_hh_stats(active_hh_she_hashes)
      hh_all_ages = active_hh_she_hashes.map { |m| m[:age] }
      hh_type = household_logic.calculate_household_type(hh_all_ages)

      {
        hh_type: hh_type,
        hh_max_age: hh_all_ages.compact.max || 0,
      }
    end

    def build_context_for_member(
      she,
      member_hash,
      hoh_data,
      hh_member_hashes:,
      hoh_length_of_stay:,
      hoh_move_in_date:,
      hh_id:,
      data_source_id:,
      active_hh_she_hashes:,
      hh_stats:
    )
      # Inherited values
      chronic_source = household_logic.calculate_chronic_status(hh_member_hashes, member_hash, hoh_data)
      inherited_move_in_date = household_logic.calculate_move_in_date(member_hash, hoh_data, report_end_date: @report.end_date)

      # SPM-specific: Calculate inherited date to street for Measure 1b
      inherited_date_to_street = household_logic.calculate_date_to_street(
        member_hash,
        hoh_data,
      )

      # Parenting youth logic (active SHEs only)
      is_parenting_youth = household_logic.calculate_is_parenting_youth(member_hash, active_hh_she_hashes)
      has_other_clients_over_25 = !household_logic.only_youth?(active_hh_she_hashes)

      HudReports::HouseholdContext.new(
        report_instance_id: @report.id,
        service_history_enrollment_id: she.id,
        data_source_id: data_source_id,
        source_enrollment_id: member_hash[:enrollment_id],
        source_client_id: member_hash[:source_client_id],
        destination_client_id: member_hash[:destination_client_id],
        age: member_hash[:age],
        dob: member_hash[:dob],
        veteran_status: member_hash[:veteran_status],
        household_id: hh_id,
        hoh_destination_client_id: hoh_data&.[](:destination_client_id),
        hoh_personal_id: hoh_data&.[](:personal_id),
        hoh_service_history_enrollment_id: hoh_data&.[](:she_id),
        hoh_entry_date: hoh_data&.[](:entry_date),
        hoh_exit_date: hoh_data&.[](:exit_date),
        hoh_length_of_stay: hoh_length_of_stay,
        hoh_coc: hoh_data&.[](:enrollment_coc),
        hoh_date_to_street: hoh_data&.[](:date_to_street),
        hoh_move_in_date: hoh_move_in_date,
        hoh_age: hoh_data&.[](:age),
        hoh_veteran_status: hoh_data&.[](:veteran_status),
        is_hoh: she.enrollment&.RelationshipToHoH == 1,
        relationship_to_hoh: member_hash[:relationship_to_hoh],
        member_chronic_status: member_hash[:chronic_status],
        member_chronic_detail: member_hash[:chronic_detail],
        household_type: hh_stats[:hh_type],
        is_parenting_youth: is_parenting_youth,
        non_youth_household: has_other_clients_over_25,
        inherited_chronic_status: chronic_source&.[](:status) || false,
        inherited_chronic_detail: chronic_source&.[](:detail),
        inherited_move_in_date: inherited_move_in_date,
        member_entry_date: member_hash[:entry_date],
        member_exit_date: member_hash[:exit_date],
        member_date_to_street: member_hash[:date_to_street],
        inherited_date_to_street: inherited_date_to_street,
        hh_max_age: hh_stats[:hh_max_age],
      )
    end

    # Returns true if the enrollment should be counted as active for household composition.
    # Non-NBN projects use Method 1 (date overlap only). NBN projects use Method 2:
    # the member must also have a bed-night service or an exit within the report range.
    def nbn_active?(she)
      date_active = (she.last_date_in_program.nil? || she.last_date_in_program >= @report.start_date) &&
                    she.first_date_in_program <= @report.end_date
      return date_active unless she.nbn?

      date_active && (@active_nbn_she_ids_in_batch || Set.new).include?(she.id)
    end

    def household_logic
      HudReports::HouseholdLogic
    end
  end
end
