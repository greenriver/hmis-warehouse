###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::MarkClientAsDirtyBehavior
  extend ActiveSupport::Concern

  included do
    after_save :mark_destination_client_dirty
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

    # enqueue
    Hmis::Ce::ChangeMarker.upsert_or_bump_version('GrdaWarehouse::Hud::Client', trackable_ids: client_ids)
  end
end
