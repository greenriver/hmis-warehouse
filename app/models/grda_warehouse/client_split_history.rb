###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  # Tracks the history of client record splits in the HMIS warehouse.
  # When a client record is split, this model maintains the relationship between
  # the original (source) client and the new (destination) client.
  #
  # This is used to:
  # - Prevent re-merging of previously split clients
  # - Track which client records were split from each other
  # - Maintain an audit trail of client record splits
  #
  # @example Creating a split history record
  #   GrdaWarehouse::ClientSplitHistory.create(
  #     split_from: original_client.id, # The id of the current destination client for the source being moved
  #     split_into: new_client.id, # The new destination client
  #     receive_hmis: true,
  #     receive_health: true
  #   )
  #
  # @see GrdaWarehouse::Hud::Client#split
  # @see GrdaWarehouse::Tasks::IdentifyDuplicates
  class ClientSplitHistory < GrdaWarehouseBase
    belongs_to :destination_client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: :id, foreign_key: :split_into, optional: true
    belongs_to :source_client, class_name: 'GrdaWarehouse::Hud::Client', primary_key: :id, foreign_key: :split_from, optional: true
  end
end
