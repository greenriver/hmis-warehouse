###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Looks up the open (WIP included) members of households. Household keys are [data_source_id, HouseholdID] pairs,
# because a HouseholdID is only unique within a data source.
class Hmis::Ce::HouseholdMembership
  include Hmis::Concerns::HmisArelHelper

  # Base scope for household.* CE match fields, which evaluate a client against their household's open members.
  # Grouped by data source so the SQL is one HouseholdID IN (...) per data source, not one clause per pair.
  # @param household_keys [Array<Array(Integer, String)>] [data_source_id, HouseholdID] pairs
  # @return [ActiveRecord::Relation<Hmis::Hud::Enrollment>] the households' open member enrollments
  def self.open_enrollments(household_keys)
    return Hmis::Hud::Enrollment.none if household_keys.empty?

    condition = household_keys.group_by(&:first).map do |data_source_id, pairs|
      e_t[:data_source_id].eq(data_source_id).and(e_t[:HouseholdID].in(pairs.map(&:last)))
    end.reduce(:or)

    Hmis::Hud::Enrollment.open_including_wip.where(condition)
  end

  # A change to one member's HMIS record can change every open member's household.* values, so the whole
  # household is marked dirty for CE, not just the record's own client.
  # @param household_keys [Array<Array(Integer, String)>] [data_source_id, HouseholdID] pairs
  # @return [Array<Integer>] destination client ids of the households' open members
  def self.open_member_destination_ids(household_keys)
    open_enrollments(household_keys).
      joins(client: :warehouse_client_source).
      distinct.
      pluck(wc_t[:destination_id])
  end

  # For warehouse dedup and cleanup, which change destination clients rather than HMIS records: a client's
  # destination demographics (e.g. DOB) feed their co-members' household.* values, so co-members are marked dirty too.
  # @param destination_client_ids [Array<Integer>]
  # @return [Array<Integer>] destination client ids of the open members of every open household the given clients
  #   belong to, including those clients
  def self.household_member_destination_ids(destination_client_ids)
    return [] if destination_client_ids.empty?

    household_keys = Hmis::Hud::Enrollment.open_including_wip.
      joins(client: :warehouse_client_source).
      where(wc_t[:destination_id].in(destination_client_ids)).
      distinct.
      pluck(e_t[:data_source_id], e_t[:HouseholdID])
    open_member_destination_ids(household_keys)
  end
end
