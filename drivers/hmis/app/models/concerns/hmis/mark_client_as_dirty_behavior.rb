###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::MarkClientAsDirtyBehavior
  extend ActiveSupport::Concern

  included do
    after_save :mark_destination_client_dirty
    after_destroy :mark_destination_client_dirty
  end

  protected

  def mark_destination_client_dirty
    return unless Hmis::Ce.configuration.enabled?

    # find the destination client
    # Note, if the destination client does not exist yet, this will be a no-op and we rely on
    # IdentifyDuplicates to mark the client as dirty
    identity_scope = Hmis::Hud::Client.where(data_source: data_source_id, personal_id: personal_id)
    client_ids = GrdaWarehouse::WarehouseClient.
      joins(:source).
      merge(identity_scope).
      pluck(:destination_id)

    # household.* CE match fields depend on other members' records, so also mark the open members of affected households
    client_ids += Hmis::Ce::Match::Expression::HouseholdSelector.open_member_destination_ids(ce_affected_households)

    # enqueue
    Hmis::Ce::ChangeMarker.upsert_or_bump_version('GrdaWarehouse::Hud::Client', trackable_ids: client_ids.uniq)
  end

  # Override to return the [data_source_id, HouseholdID] pairs whose open members should be marked dirty
  # when this record changes.
  def ce_affected_households
    []
  end
end
