###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # Picks the single household that represents each destination client for household.* fields.
  #
  # Only open households count: the client's own enrollment must be open (WIP included; ExitDate today is exited)
  # and in the global eligibility project group. The eligibility lookback window does not apply.
  # The household with the most open members wins. Ties go to the most recent HoH EntryDate, then the
  # client's most recently updated enrollment, then the client's highest enrollment id.
  class HouseholdSelector
    include Hmis::Concerns::HmisArelHelper

    def initialize(configuration: Hmis::Ce.configuration)
      @configuration = configuration
    end

    # @param destination_client_ids [Array<Integer>]
    # @return [Hash{Integer => Array(Integer, String)}] destination client id => [data_source_id, HouseholdID].
    #   Clients with no open in-scope household are absent.
    def call(destination_client_ids)
      destination_client_ids = Array(destination_client_ids)
      return {} if destination_client_ids.empty?

      client_enrollments = client_enrollment_rows(destination_client_ids)
      return {} if client_enrollments.empty?

      stats = household_stats(client_enrollments.map { |row| row[:household] }.uniq)

      client_enrollments.group_by { |row| row[:destination_id] }.transform_values do |rows|
        rows.max_by do |row|
          household = stats.fetch(row[:household])
          [household[:size], household[:hoh_entry_date] || Date.new(0), row[:date_updated] || Time.at(0), row[:id]]
        end[:household]
      end
    end

    private

    def client_enrollment_rows(destination_client_ids)
      scope = Hmis::Hud::Enrollment.open_including_wip.
        joins(client: :warehouse_client_source).
        where(wc_t[:destination_id].in(destination_client_ids))
      scope = eligibility_scope.apply_project_group_filter(scope)

      scope.pluck(wc_t[:destination_id], e_t[:data_source_id], e_t[:HouseholdID], e_t[:DateUpdated], e_t[:id]).
        map do |destination_id, data_source_id, household_id, date_updated, id|
          { destination_id: destination_id, household: [data_source_id, household_id], date_updated: date_updated, id: id }
        end
    end

    # @param household_keys [Array<Array(Integer, String)>] [data_source_id, HouseholdID] pairs
    # @return [Hash{Array(Integer, String) => Hash}] household key => { size:, hoh_entry_date: }
    def household_stats(household_keys)
      Hmis::Ce::HouseholdMembership.open_enrollments(household_keys).
        pluck(e_t[:data_source_id], e_t[:HouseholdID], e_t[:RelationshipToHoH], e_t[:EntryDate]).
        group_by { |data_source_id, household_id, _, _| [data_source_id, household_id] }.
        transform_values do |rows|
          hoh_entry_date = rows.select { |_, _, relationship, _| relationship == 1 }.map(&:last).compact.max
          { size: rows.size, hoh_entry_date: hoh_entry_date }
        end
    end

    def eligibility_scope
      @eligibility_scope ||= EnrollmentEligibilityScope.new(configuration: @configuration)
    end
  end
end
