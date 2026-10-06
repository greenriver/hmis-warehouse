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

    # Open (WIP included) member enrollments of the given households.
    #
    # @param households [Array<Array(Integer, String)>] [data_source_id, HouseholdID] pairs
    # @return [ActiveRecord::Relation<Hmis::Hud::Enrollment>]
    def self.open_member_enrollments(households)
      return Hmis::Hud::Enrollment.none if households.empty?

      # HouseholdIDs are only unique within a data source
      condition = households.group_by(&:first).map do |data_source_id, pairs|
        e_t[:data_source_id].eq(data_source_id).and(e_t[:HouseholdID].in(pairs.map(&:last)))
      end.reduce(:or)

      Hmis::Hud::Enrollment.open_including_wip.where(condition)
    end

    # Destination client ids of the open members of the given households.
    #
    # @param households [Array<Array(Integer, String)>] [data_source_id, HouseholdID] pairs
    # @return [Array<Integer>]
    def self.open_member_destination_ids(households)
      open_member_enrollments(households).
        joins(client: :warehouse_client_source).
        pluck(wc_t[:destination_id])
    end

    # Destination client ids of the open members of every open household the given destination clients belong to.
    # Not limited to the eligibility project group; marking extra clients dirty is harmless.
    #
    # @param destination_client_ids [Array<Integer>]
    # @return [Array<Integer>]
    def self.open_household_member_destination_ids(destination_client_ids)
      return [] if destination_client_ids.empty?

      households = Hmis::Hud::Enrollment.open_including_wip.
        joins(client: :warehouse_client_source).
        where(wc_t[:destination_id].in(destination_client_ids)).
        distinct.
        pluck(e_t[:data_source_id], e_t[:HouseholdID])
      open_member_destination_ids(households)
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

    # @return [Hash{Array(Integer, String) => Hash}] household => { size:, hoh_entry_date: }
    def household_stats(households)
      self.class.open_member_enrollments(households).
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
