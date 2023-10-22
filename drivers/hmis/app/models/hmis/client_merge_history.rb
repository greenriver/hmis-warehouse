###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ClientMergeHistory < Hmis::HmisBase
  belongs_to :client_merge_audit, class_name: 'Hmis::ClientMergeAudit', optional: false, foreign_key: :client_merge_audit_id, inverse_of: :client_merge_histories
  belongs_to :retained_client, class_name: 'Hmis::Hud::Client', optional: true
  belongs_to :deleted_client, class_name: 'Hmis::Hud::Client', optional: true
end
