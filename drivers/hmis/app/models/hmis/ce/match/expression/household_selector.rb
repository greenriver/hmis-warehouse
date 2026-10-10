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

    SELF_HEAD_OF_HOUSEHOLD = HudHelper.util.relationship_to_hoh('Self (head of household)', true)

    # @!attribute key [Array(Integer, String)] [data_source_id, HouseholdID]
    # @!attribute size [Integer] number of people with an open member enrollment.
    # @!attribute hoh_entry_date [Date, nil] latest EntryDate among open HoH enrollments
    # @!attribute member_destination_ids [Array<Integer>] distinct destination ids of the open members
    Household = Data.define(:key, :size, :hoh_entry_date, :member_destination_ids)

    # One of a requested client's open, in-scope enrollments
    ClientEnrollment = Data.define(:destination_id, :data_source_id, :household_id, :date_updated, :id) do
      def household_key
        [data_source_id, household_id]
      end
    end

    # One open member enrollment of a candidate household
    MemberEnrollment = Data.define(:data_source_id, :household_id, :relationship_to_hoh, :entry_date, :destination_id) do
      def household_key
        [data_source_id, household_id]
      end

      def head_of_household?
        relationship_to_hoh == SELF_HEAD_OF_HOUSEHOLD
      end
    end

    def initialize(configuration: Hmis::Ce.configuration)
      @configuration = configuration
    end

    # @param destination_client_ids [Array<Integer>]
    # @return [Hash{Integer => Household}] destination client id => selected household. Clients with no open
    #   in-scope household are absent.
    def call(destination_client_ids)
      destination_client_ids = Array(destination_client_ids)
      return {} if destination_client_ids.empty?

      client_enrollments = load_client_enrollments(destination_client_ids)
      return {} if client_enrollments.empty?

      households_by_key = open_households(client_enrollments.map(&:household_key).uniq)

      # A household missing here lost its open members after load_client_enrollments (concurrent exit/delete)
      candidates = client_enrollments.select { |enrollment| households_by_key.key?(enrollment.household_key) }

      candidates.group_by(&:destination_id).transform_values do |enrollments|
        best = enrollments.max_by { |enrollment| selection_rank(enrollment, households_by_key[enrollment.household_key]) }
        households_by_key[best.household_key]
      end
    end

    private

    # Sort key for the tie-break order in the class doc; nil dates sort first
    def selection_rank(client_enrollment, household)
      [
        household.size,
        household.hoh_entry_date || Date.new(0),
        client_enrollment.date_updated || Time.at(0),
        client_enrollment.id,
      ]
    end

    def load_client_enrollments(destination_client_ids)
      scope = Hmis::Hud::Enrollment.open_including_wip.
        joins(client: :warehouse_client_source).
        where(wc_t[:destination_id].in(destination_client_ids))
      scope = eligibility_scope.apply_project_group_filter(scope)

      pluck_as(
        ClientEnrollment,
        scope,
        destination_id: wc_t[:destination_id],
        data_source_id: e_t[:data_source_id],
        household_id: e_t[:HouseholdID],
        date_updated: e_t[:DateUpdated],
        id: e_t[:id],
      )
    end

    # @param household_keys [Array<Array(Integer, String)>] [data_source_id, HouseholdID] pairs
    # @return [Hash{Array(Integer, String) => Household}] households that still have open members
    def open_households(household_keys)
      member_enrollments = pluck_as(
        MemberEnrollment,
        Hmis::Ce::HouseholdMemberLookup.open_enrollments(household_keys).left_outer_joins(client: :warehouse_client_source),
        data_source_id: e_t[:data_source_id],
        household_id: e_t[:HouseholdID],
        relationship_to_hoh: e_t[:RelationshipToHoH],
        entry_date: e_t[:EntryDate],
        destination_id: wc_t[:destination_id],
      )

      member_enrollments.group_by(&:household_key).to_h do |household_key, members|
        destination_ids = members.map(&:destination_id)
        household = Household.new(
          key: household_key,
          size: destination_ids.compact.uniq.size + destination_ids.count(nil),
          hoh_entry_date: members.select(&:head_of_household?).filter_map(&:entry_date).max,
          member_destination_ids: destination_ids.compact.uniq,
        )
        [household_key, household]
      end
    end

    # Plucks the columns and builds one data_class per row, keyed by the column names given
    # @param columns [Hash{Symbol => Arel::Attributes::Attribute}] data_class attribute => column
    def pluck_as(data_class, scope, **columns)
      scope.pluck(*columns.values).map { |row| data_class.new(**columns.keys.zip(row).to_h) }
    end

    def eligibility_scope
      @eligibility_scope ||= EnrollmentEligibilityScope.new(configuration: @configuration)
    end
  end
end
