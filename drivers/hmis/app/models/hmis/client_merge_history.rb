###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Links a retained client to each client deleted in a merge (for search and UI).
# Destroyed by UndoMergeClientsJob when a merge is "undone"; the associated ClientMergeAudit preserves the audit trail.
#
# See docs/features/hmis_client_merges.md for more details.
class Hmis::ClientMergeHistory < Hmis::HmisBase
  belongs_to :client_merge_audit, class_name: 'Hmis::ClientMergeAudit', optional: false, foreign_key: :client_merge_audit_id, inverse_of: :client_merge_histories
  belongs_to :retained_client, class_name: 'Hmis::Hud::Client', optional: true
  belongs_to :deleted_client, class_name: 'Hmis::Hud::Client', optional: true
end
