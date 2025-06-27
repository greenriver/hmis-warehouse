###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::MarkAsDirtyBehavior
  extend ActiveSupport::Concern

  included do
    after_save :mark_destination_client_dirty
  end

  protected

  def mark_destination_client_dirty
    # find the destination client
    identity_scope = Hmis::Hud::Client.where(data_source: data_source_id, personal_id: personal_id)
    client_ids = Hmis::WarehouseClient.
      joins(:source).
      merge(identity_scope).
      pluck(:destination_id)

    # enqueue
    GrdaWarehouse::ClientChangeMarker.upsert_or_bump_version(client_ids: client_ids)
  end
end
