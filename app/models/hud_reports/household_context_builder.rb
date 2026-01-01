# frozen_string_literal: true

module HudReports
  class HouseholdContextBuilder
    def self.call(...)
      new(...).call
    end

    def initialize(generator, report)
      @generator = generator
      @report = report
    end

    def call
      # Idempotency: clear existing context for this report run
      @report.household_contexts.delete_all

      contexts = []
      each_household_id_batch do |batch|
        all_members_by_hh = load_unfiltered_members(batch).group_by { |she| get_hh_id(she) }

        all_members_by_hh.each do |hh_id, members|
          contexts.concat(build_contexts_for_household(hh_id, members))
        end

        if contexts.size >= import_batch_size
          HudReports::HouseholdContext.import!(contexts)
          contexts = []
        end
      end

      HudReports::HouseholdContext.import!(contexts) if contexts.any?

      # Update count on report instance
      @report.update!(household_context_count: @report.household_contexts.count)
    end

    private

    def batch_size
      500
    end

    def import_batch_size
      2000
    end

    def get_hh_id(she)
      she.household_id || "#{she.enrollment_group_id}*HH"
    end

    def each_household_id_batch
      # Get unique HH IDs for the report universe by driving directly from ServiceHistoryEnrollment.
      # We drive from the clients that are in the report universe.
      hh_ids_query = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        where(client_id: @generator.client_scope).
        merge(@generator.report_scope_source.open_between(start_date: @report.start_date, end_date: @report.end_date))

      # Plucking all unique HH identifiers. For most datasets, this list fits in memory.
      # This is simpler and more robust than driving through client_scope.in_batches.
      hh_ids = hh_ids_query.distinct.pluck(:household_id, :enrollment_group_id).map do |hh_id, eg_id|
        hh_id || "#{eg_id}*HH"
      end.uniq

      hh_ids.each_slice(batch_size) do |batch|
        yield batch
      end
    end

    def load_unfiltered_members(household_ids)
      real_hh_ids = household_ids.reject { |id| id.end_with?('*HH') }
      synthetic_eg_ids = household_ids.select { |id| id.end_with?('*HH') }.map { |id| id.sub('*HH', '') }

      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
        open_between(start_date: @report.start_date, end_date: @report.end_date).
        preload(enrollment: [:client, :disabilities, :project])

      query = if real_hh_ids.any? && synthetic_eg_ids.any?
        scope.where(household_id: real_hh_ids).or(scope.where(enrollment_group_id: synthetic_eg_ids, household_id: nil))
      elsif real_hh_ids.any?
        scope.where(household_id: real_hh_ids)
      else
        scope.where(enrollment_group_id: synthetic_eg_ids, household_id: nil)
      end

      query.to_a
    end

    def build_contexts_for_household(hh_id, members)
      # Pre-calculate common HH values
      hh_member_hashes = members.map do |m|
        date = [m.first_date_in_program, @report.start_date].max
        age = GrdaWarehouse::Hud::Client.age(date: date, dob: m.enrollment&.client&.DOB)

        # Determine report_date for chronic calculation
        report_date = @generator.filter&.on if @generator.respond_to?(:filter) && @generator.filter.present?
        report_date ||= m.enrollment&.EntryDate

        {
          she_id: m.id,
          enrollment_id: m.enrollment&.id,
          client_id: m.client_id,
          entry_date: m.first_date_in_program,
          exit_date: m.last_date_in_program,
          age: age,
          chronic_status: m.enrollment&.chronically_homeless_at_start?,
          pit_chronic_status: m.enrollment&.chronically_homeless_at_start?(date: report_date),
          chronic_detail: m.enrollment&.chronically_homeless_at_start,
          chronic_detail: m.enrollment&.chronically_homeless_at_start,
          relationship_to_hoh: m.enrollment&.RelationshipToHoH,
          move_in_date: m.move_in_date,
          veteran_status: m.enrollment&.client&.VeteranStatus,
          enrollment_coc: m.enrollment&.EnrollmentCoC,
          date_to_street: m.enrollment&.DateToStreetESSH,
          entry_date: m.first_date_in_program,
        }
      end

      # HH Level Stats
      hoh_data = hh_member_hashes.detect { |m| m[:relationship_to_hoh] == 1 }
      hh_ages = hh_member_hashes.map { |m| m[:age] }.compact
      hh_type = calculate_household_type(hh_ages)
      hh_max_age = hh_ages.max || 0
      hh_member_count = members.size
      hh_has_minor_children = hh_member_hashes.any? { |m| m[:relationship_to_hoh] == 2 && m[:age] && m[:age] < 18 }
      hh_max_age_of_parents = hh_member_hashes.select { |m| [1, 3].include?(m[:relationship_to_hoh]) }.map { |m| m[:age] }.compact.max || 0

      members.map do |m|
        member_hash = hh_member_hashes.detect { |mh| mh[:she_id] == m.id }

        # Inherited values
        chronic_source = calculate_chronic_status(hh_member_hashes, member_hash, hoh_data)
        inherited_move_in_date = calculate_move_in_date(member_hash, hoh_data)

        # Parenting youth logic
        is_parenting_youth = calculate_is_parenting_youth(member_hash, hh_member_hashes)
        has_other_clients_over_25 = !only_youth?(hh_member_hashes)

        HudReports::HouseholdContext.new(
          report_instance_id: @report.id,
          service_history_enrollment_id: m.id,
          source_enrollment_id: member_hash[:enrollment_id],
          source_client_id: m.client_id,
          age: member_hash[:age],
          household_id: hh_id,
          hoh_id: hoh_data&.[](:client_id),
          hoh_service_history_enrollment_id: hoh_data&.[](:she_id),
          hoh_entry_date: hoh_data&.[](:entry_date),
          hoh_coc: hoh_data&.[](:enrollment_coc),
          hoh_date_to_street: hoh_data&.[](:date_to_street),
          hoh_move_in_date: hoh_data&.[](:move_in_date),
          hoh_age: hoh_data&.[](:age),
          hoh_veteran: hoh_data&.[](:veteran_status) == 1,
          is_hoh: m.enrollment&.RelationshipToHoH == 1,
          household_type: hh_type,
          is_parenting_youth: is_parenting_youth,
          has_other_clients_over_25: has_other_clients_over_25,
          inherited_chronic_status: chronic_source&.[](:chronic_status) || false,
          inherited_chronic_detail: chronic_source&.[](:chronic_detail),
          inherited_move_in_date: inherited_move_in_date,
          member_count: hh_member_count,
          hh_max_age: hh_max_age,
          hh_has_minor_children: hh_has_minor_children,
          hh_max_age_of_parents: hh_max_age_of_parents,
        )
      end
    end

    def calculate_household_type(ages)
      adults = ages.any? { |a| a >= 18 }
      children = ages.any? { |a| a < 18 }

      if adults && children
        :adults_and_children
      elsif adults
        :adults_only
      elsif children
        :children_only
      else
        :unknown
      end
    end

    def calculate_chronic_status(hh_members, current_member, hoh, chronic_status_key: :chronic_status)
      return nil if hh_members.empty?

      # When no specific member is provided (PIT), use the HoH as the current_member
      current_member ||= hoh
      return nil unless current_member

      current_member_entry_date = current_member[:entry_date]
      hoh_entry_date = hoh&.[](:entry_date)

      # HoH if they are chronically homeless
      return { chronic_status: true, chronic_detail: hoh[:chronic_detail] } if hoh && hoh[chronic_status_key] && hoh_entry_date == current_member_entry_date

      # If the HoH is not chronically homeless, check if any other adult is
      chronic_adult = hh_members.detect do |hm|
        next false unless hm[:age]

        adult_is_chronic = hm[:age] >= 18 && hm[chronic_status_key]
        adult_matches_entry_date = hm[:entry_date] == hoh_entry_date
        adult_is_chronic && adult_matches_entry_date
      end

      return { chronic_status: true, chronic_detail: chronic_adult[:chronic_detail] } if chronic_adult

      # if no adults are either yes or no, use self for adults
      return { chronic_status: current_member[chronic_status_key], chronic_detail: current_member[:chronic_detail] } if current_member[:age] && current_member[:age] >= 18

      # if the data is bad and we don't have an HoH, use our own record
      return { chronic_status: current_member[chronic_status_key], chronic_detail: current_member[:chronic_detail] } if hoh.blank?

      # and the HoH enrollment for children if HoH status is unknown
      return { chronic_status: hoh[chronic_status_key], chronic_detail: hoh[:chronic_detail] } if hoh[:chronic_detail].in?([:dk_or_r, :missing])

      # if we have an indeterminate response for the child, use the hoh
      return { chronic_status: hoh[chronic_status_key], chronic_detail: hoh[:chronic_detail] } if current_member[:chronic_detail].in?([:dk_or_r, :missing])

      { chronic_status: current_member[chronic_status_key], chronic_detail: current_member[:chronic_detail] }
    end

    def calculate_move_in_date(member, hoh)
      # If the move-in-date is valid, just use it
      return member[:move_in_date] if member[:move_in_date].present? && member[:move_in_date] >= member[:entry_date]

      # HoH does not exist or does not have a move-in date - cannot do further calculations
      return nil unless hoh && hoh[:move_in_date].present?

      # Heads of household with move-in dates prior to their project start dates should have them disregarded
      return nil unless hoh[:entry_date] <= hoh[:move_in_date]

      # When a household member was already in the household when they became housed
      return hoh[:move_in_date] if (member[:entry_date]..member[:exit_date]).cover?(hoh[:move_in_date])

      # When a household member joins the household after they are already housed
      return member[:entry_date] if member[:entry_date] > hoh[:move_in_date]

      nil
    end

    def calculate_is_parenting_youth(member, hh_members)
      age = member[:age]
      adult = age && age >= 18
      (member[:relationship_to_hoh] == 1 || adult) && only_youth?(hh_members) && any_children?(hh_members)
    end

    def only_youth?(hh_members)
      hh_members.all? { |m| m[:age] && m[:age] <= 24 }
    end

    def any_children?(hh_members)
      hh_members.any? { |m| m[:relationship_to_hoh] == 2 && m[:age] && m[:age] < 18 }
    end
  end
end
