###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# backed by a db view
module Hmis
  class ClientAccessSummary < ApplicationRecord
    self.table_name = 'hmis_user_client_activity_log_summaries'
    self.primary_key = 'id'

    belongs_to :user, class_name: 'Hmis::User'
    belongs_to :client, class_name: 'Hmis::Hud::Client'

    def readonly?
      true
    end

    def self.apply_filter(user:, starts_on: nil, search_term: nil)
      scope = self
      if starts_on
        date_range = (starts_on...)
        log_scope = Hmis::ActivityLog.where(user_id: user.id).
          where(created_at: date_range).
          joins('JOIN hmis_activity_logs_clients ON hmis_activity_logs_clients.activity_log_id = hmis_activity_logs.id')
        scope = scope.where(client_id: log_scope.select(:client_id))
      end
      if search_term.present?
        clients = Hmis::Hud::Client.with_deleted.matching_search_term(search_term).limit(50)
        scope = scope.where(client_id: clients.pluck(:id))
      end
      scope.where(user_id: user.id)
    end
  end
end
