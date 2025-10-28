###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::ClientMergeAudit < Hmis::HmisBase
  belongs_to :actor, class_name: 'Hmis::User'
  has_many :client_merge_histories, class_name: 'Hmis::ClientMergeHistory', inverse_of: :client_merge_audit
  has_many :retained_clients, class_name: 'Hmis::Hud::Client', through: :client_merge_histories
  has_many :deleted_clients, class_name: 'Hmis::Hud::Client', through: :client_merge_histories

  has_one :most_recent_merge_history, -> { order(updated_at: :desc) }, class_name: 'Hmis::ClientMergeHistory'
  has_one :retained_client, class_name: 'Hmis::Hud::Client', through: :most_recent_merge_history

  scope :viewable_by, ->(user) do
    # can_merge_clients? is typically a global permission, but just in case, filter to clients viewable by the current user
    joins(:retained_client).merge(Hmis::Hud::Client.viewable_by(user))
  end

  def self.apply_filters(input)
    Hmis::Filter::ClientMergeAuditFilter.new(input).filter_scope(self)
  end
end
