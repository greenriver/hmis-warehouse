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

    def universe_she_ids
      enrollment_scope.pluck(:id).to_set
    end

    def copy_contexts_from_source
      # Validate date ranges match
      source_report = HudReports::ReportInstance.find(@source_report_id)
      unless source_report.start_date == @report.start_date &&
             source_report.end_date == @report.end_date
        raise ArgumentError, "Cannot share contexts: date ranges don't match"
      end

      # Discover which SHE IDs this report needs
      needed_she_ids = enrollment_scope.pluck(:id)

      return if needed_she_ids.empty?

      HudReports::HouseholdContext.copy_subset!(
        source_report_id: @source_report_id,
        target_report_id: @report.id,
        service_history_enrollment_ids: needed_she_ids,
      )
    end

    attr_reader :enrollment_scope

    def build_contexts_from_scratch
      contexts = []
      universe_ids = universe_she_ids
      each_household_batch do |batch|
        # batch is array of [hh_id, data_source_id]
        all_members = load_unfiltered_members(batch)
        all_members_by_hh = all_members.group_by { |she| [get_hh_id(she), she.data_source_id] }

        all_members_by_hh.each do |(hh_id, data_source_id), members|
          household_contexts = build_contexts_for_household(hh_id, data_source_id, members)
          # Only keep contexts for members that are part of the report universe
          contexts.concat(household_contexts.select { |c| universe_ids.include?(c.service_history_enrollment_id) })
        end

        if contexts.size >= import_batch_size
          HudReports::HouseholdContext.import!(contexts)
          contexts = []
        end
      end

      HudReports::HouseholdContext.import!(contexts) if contexts.any?
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

    def each_household_batch
      # Get unique HH IDs + data_source_id for the report universe
      hh_ids_query = enrollment_scope

      she_table = GrdaWarehouse::ServiceHistoryEnrollment.arel_table

      # We drive batching using the same synthetic ID logic as get_hh_id.
      # The '*HH' suffix ensures we don't conflate a real HouseholdID with a synthetic one
      # derived from an EnrollmentID of the same value within the same data source.
      hh_id_expr = Arel::Nodes::NamedFunction.new(
        'COALESCE',
        [
          she_table[:household_id],
          Arel::Nodes::InfixOperation.new('||', she_table[:enrollment_group_id], Arel::Nodes.build_quoted('*HH')),
        ],
      )

      base_query = hh_ids_query.
        distinct.
        order(hh_id_expr, she_table[:data_source_id])

      last_hh_id = nil
      last_ds_id = nil

      loop do
        query = base_query.limit(batch_size)

        if last_hh_id
          # Seek logic for composite order
          condition = hh_id_expr.gt(last_hh_id).or(
            hh_id_expr.eq(last_hh_id).and(she_table[:data_source_id].gt(last_ds_id)),
          )
          query = query.where(condition)
        end

        # We need both values
        batch = query.pluck(hh_id_expr, she_table[:data_source_id])
        break if batch.empty?

        yield batch
        last_hh_id, last_ds_id = batch.last
      end
    end

    def load_unfiltered_members(batch)
      # batch is array of [hh_id, data_source_id]
      # We group by data_source_id to make queries more efficient (fewer IN clauses)
      members = []
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

        members.concat(query.to_a.select { |m| m.enrollment.present? })
      end
      members
    end

    def build_contexts_for_household(hh_id, data_source_id, members)
      # Pre-calculate common HH values
      hh_member_hashes = members.map do |m|
        enrollment = m.enrollment
        source_client = enrollment&.client
        date = [m.first_date_in_program, @report.start_date].max
        age = GrdaWarehouse::Hud::Client.age(date: date, dob: source_client&.DOB)

        # Determine report_date for chronic calculation
        report_date = @generator.filter&.on if @generator.respond_to?(:filter) && @generator.filter.present?

        chronic_at_start = enrollment&.chronically_homeless_at_start
        if report_date.blank? || report_date == enrollment&.EntryDate
          pit_chronic_at_start = chronic_at_start
        else
          pit_chronic_at_start = enrollment&.chronically_homeless_at_start(date: report_date)
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
          chronic_status: chronic_at_start == :yes,
          pit_chronic_status: pit_chronic_at_start == :yes,
          chronic_detail: chronic_at_start,
          pit_chronic_detail: pit_chronic_at_start,
          relationship_to_hoh: enrollment&.RelationshipToHoH,
          move_in_date: m.move_in_date,
          veteran_status: source_client&.VeteranStatus,
          enrollment_coc: enrollment&.EnrollmentCoC,
          date_to_street: enrollment&.DateToStreetESSH,
        }
      end

      # HH Level Stats
      # For household composition and veteran stats, only consider members active during the report period.
      # Historical members (from lookback) are used for inheritance but should not affect the current report's household type.
      active_hh_member_hashes = hh_member_hashes.select do |mh|
        (mh[:exit_date].nil? || mh[:exit_date] >= @report.start_date) && mh[:entry_date] <= @report.end_date
      end

      hoh_data = hh_member_hashes.detect { |m| m[:relationship_to_hoh] == 1 }
      hoh_adjusted_move_in_date = (HudReports::HouseholdLogic.calculate_move_in_date(hoh_data, hoh_data, report_end_date: @report.end_date) if hoh_data)

      hoh_stayer_end_date = [hoh_data&.[](:exit_date), @report.end_date + 1.day].compact.min
      hoh_length_of_stay = if hoh_data && hoh_stayer_end_date
        (hoh_stayer_end_date - hoh_data[:entry_date]).to_i
      else
        0
      end

      hh_all_ages = active_hh_member_hashes.map { |m| m[:age] }
      hh_type = HudReports::HouseholdLogic.calculate_household_type(hh_all_ages)

      hh_ages = hh_all_ages.compact
      hh_max_age = hh_ages.max || 0
      hh_member_count = active_hh_member_hashes.size
      hh_has_minor_children = active_hh_member_hashes.any? { |m| m[:relationship_to_hoh] == 2 && m[:age] && m[:age] < 18 }
      hh_max_age_of_parents = active_hh_member_hashes.select { |m| [1, 3].include?(m[:relationship_to_hoh]) }.map { |m| m[:age] }.compact.max || 0

      # Veteran Stats (active members only)
      hh_adults = active_hh_member_hashes.select { |m| m[:age] && m[:age] >= 18 }
      hh_veterans = hh_adults.select { |m| m[:veteran_status] == 1 }

      hh_any_veteran_chronic = hh_veterans.any? { |m| m[:chronic_status] == true }
      hh_any_veteran_non_chronic = hh_veterans.any? { |m| m[:chronic_status] == false }
      hh_all_adult_non_veteran = hh_adults.present? && hh_adults.all? { |m| m[:veteran_status]&.zero? }
      hh_any_adult_refused_veteran = hh_adults.any? { |m| [8, 9].include?(m[:veteran_status]) }
      hh_any_adult_missing_veteran = hh_adults.any? { |m| m[:veteran_status] == 99 }

      members.map do |m|
        member_hash = hh_member_hashes.detect { |mh| mh[:she_id] == m.id }

        # Inherited values
        chronic_source = HudReports::HouseholdLogic.calculate_chronic_status(hh_member_hashes, member_hash, hoh_data)
        pit_chronic_source = HudReports::HouseholdLogic.calculate_chronic_status(hh_member_hashes, member_hash, hoh_data, chronic_status_key: :pit_chronic_status)
        inherited_move_in_date = HudReports::HouseholdLogic.calculate_move_in_date(member_hash, hoh_data, report_end_date: @report.end_date)

        # SPM-specific: Calculate inherited date to street for Measure 1b
        inherited_date_to_street = HudReports::HouseholdLogic.calculate_date_to_street(
          member_hash,
          hoh_data,
        )

        # Parenting youth logic (active members only)
        is_parenting_youth = HudReports::HouseholdLogic.calculate_is_parenting_youth(member_hash, active_hh_member_hashes)
        has_other_clients_over_25 = !HudReports::HouseholdLogic.only_youth?(active_hh_member_hashes)

        HudReports::HouseholdContext.new(
          report_instance_id: @report.id,
          service_history_enrollment_id: m.id,
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
          hoh_move_in_date: hoh_adjusted_move_in_date,
          hoh_age: hoh_data&.[](:age),
          hoh_veteran: hoh_data&.[](:veteran_status) == 1,
          is_hoh: m.enrollment&.RelationshipToHoH == 1,
          relationship_to_hoh: member_hash[:relationship_to_hoh],
          pit_chronic_status: member_hash[:pit_chronic_status],
          household_type: hh_type,
          is_parenting_youth: is_parenting_youth,
          has_other_clients_over_25: has_other_clients_over_25,
          inherited_chronic_status: chronic_source&.[](:status) || false,
          inherited_chronic_detail: chronic_source&.[](:detail),
          inherited_pit_chronic_status: pit_chronic_source&.[](:status) || false,
          inherited_pit_chronic_detail: pit_chronic_source&.[](:detail),
          inherited_move_in_date: inherited_move_in_date,
          member_entry_date: member_hash[:entry_date],
          member_date_to_street: member_hash[:date_to_street],
          inherited_date_to_street: inherited_date_to_street,
          member_count: hh_member_count,
          hh_max_age: hh_max_age,
          hh_has_minor_children: hh_has_minor_children,
          hh_max_age_of_parents: hh_max_age_of_parents,
          hh_any_veteran_chronic: hh_any_veteran_chronic,
          hh_any_veteran_non_chronic: hh_any_veteran_non_chronic,
          hh_all_adult_non_veteran: hh_all_adult_non_veteran,
          hh_any_adult_refused_veteran: hh_any_adult_refused_veteran,
          hh_any_adult_missing_veteran: hh_any_adult_missing_veteran,
        )
      end
    end
  end
end
