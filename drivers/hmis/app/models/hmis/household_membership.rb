###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Looks up the open (WIP included) members of households. Households are [data_source_id, HouseholdID] pairs,
# because a HouseholdID is only unique within a data source.
class Hmis::HouseholdMembership
  include Hmis::Concerns::HmisArelHelper

  # @param households [Array<Array(Integer, String)>] [data_source_id, HouseholdID] pairs
  # @return [ActiveRecord::Relation<Hmis::Hud::Enrollment>] the households' open member enrollments
  def self.open_enrollments(households)
    return Hmis::Hud::Enrollment.none if households.empty?

    condition = households.group_by(&:first).map do |data_source_id, pairs|
      e_t[:data_source_id].eq(data_source_id).and(e_t[:HouseholdID].in(pairs.map(&:last)))
    end.reduce(:or)

    Hmis::Hud::Enrollment.open_including_wip.where(condition)
  end

  # @param households [Array<Array(Integer, String)>] [data_source_id, HouseholdID] pairs
  # @return [Array<Integer>] destination client ids of the households' open members
  def self.open_member_destination_ids(households)
    open_enrollments(households).
      joins(client: :warehouse_client_source).
      pluck(wc_t[:destination_id])
  end

  # @param destination_client_ids [Array<Integer>]
  # @return [Array<Integer>] destination client ids of the open members of every open household the given clients
  #   belong to, including those clients
  def self.household_member_destination_ids(destination_client_ids)
    return [] if destination_client_ids.empty?

    households = Hmis::Hud::Enrollment.open_including_wip.
      joins(client: :warehouse_client_source).
      where(wc_t[:destination_id].in(destination_client_ids)).
      distinct.
      pluck(e_t[:data_source_id], e_t[:HouseholdID])
    open_member_destination_ids(households)
  end
end
