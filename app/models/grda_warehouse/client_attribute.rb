###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Stores per-client attributes that don't belong in the HUD data model.
# One row per destination client; additional columns can be added here as new
# per-client needs arise rather than creating new single-purpose tables.
#
# == External Data Sharing Exclusion
#
# Agencies can mark a client to be excluded from exports shared with external
# parties (e.g. third-party analytics or research exports). The feature is
# gated by the :enable_external_data_sharing_exclusion config flag.
#
# The exclusion flag is a nullable boolean:
#   nil   — never explicitly set; treat the same as "not excluded"
#   true  — client is excluded from external data sharing
#   false — client was explicitly included after a prior exclusion (unchecked)
#
# A row may exist for a client even when the exclusion flag is nil, because
# future attributes stored here may be set independently. Always guard on
# the flag value, not on row presence.
#
# The audit columns external_data_sharing_updated_by (warehouse user id) and
# external_data_sharing_updated_at record who last changed the exclusion flag
# and when. They are meaningful only when the flag is non-nil.
module GrdaWarehouse
  class ClientAttribute < GrdaWarehouseBase
    has_paper_trail

    belongs_to :destination_client,
               optional: true,
               class_name: 'GrdaWarehouse::Hud::Client',
               foreign_key: :client_id
  end
end
