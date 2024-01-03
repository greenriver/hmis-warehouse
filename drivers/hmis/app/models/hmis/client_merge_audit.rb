###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ClientMergeAudit < Hmis::HmisBase
  belongs_to :actor, class_name: 'Hmis::User'
  has_many :client_merge_histories, class_name: 'Hmis::ClientMergeHistory', inverse_of: :client_merge_audit
  has_many :retained_clients, class_name: 'Hmis::Hud::Client', through: :client_merge_histories
  has_many :deleted_clients, class_name: 'Hmis::Hud::Client', through: :client_merge_histories

  has_one :most_recent_merge_history, -> { order(updated_at: :desc) }, class_name: 'Hmis::ClientMergeHistory'
  has_one :retained_client, class_name: 'Hmis::Hud::Client', through: :most_recent_merge_history

  def self.apply_filters(input)
    Hmis::Filter::ClientMergeAuditFilter.new(input).filter_scope(self)
  end
end
