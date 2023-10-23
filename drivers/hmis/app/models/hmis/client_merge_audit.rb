###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ClientMergeAudit < Hmis::HmisBase
  belongs_to :actor, class_name: 'Hmis::User'
  has_many :client_merge_histories, class_name: 'Hmis::ClientMergeHistory', inverse_of: :client_merge_audit
end
