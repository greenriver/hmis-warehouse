###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Looks up the open (WIP included) members of households. Household keys are [data_source_id, HouseholdID] pairs,
# because a HouseholdID is only unique within a data source.
class Hmis::Ce::HouseholdMemberLookup
  include Hmis::Concerns::HmisArelHelper

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

  # Members whose client has no warehouse link have no destination id and are left out.
  # @param household_keys [Array<Array(Integer, String)>] [data_source_id, HouseholdID] pairs
  # @return [Array<Integer>] destination client ids of the households' open members
  def self.open_member_destination_ids(household_keys)
    open_enrollments(household_keys).
      joins(client: :warehouse_client_source).
      distinct.
      pluck(wc_t[:destination_id])
  end

  # Expands destination clients to include everyone who shares an open household with them.
  # @param destination_client_ids [Array<Integer>]
  # @return [Array<Integer>] the given clients, plus the open members of every open household they belong to
  def self.with_open_household_members(destination_client_ids)
    return [] if destination_client_ids.empty?

    household_keys = Hmis::Hud::Enrollment.open_including_wip.
      joins(client: :warehouse_client_source).
      where(wc_t[:destination_id].in(destination_client_ids)).
      distinct.
      pluck(e_t[:data_source_id], e_t[:HouseholdID])
    (destination_client_ids + open_member_destination_ids(household_keys)).uniq
  end
end
