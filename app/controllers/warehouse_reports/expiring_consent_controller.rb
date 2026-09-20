###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  class ExpiringConsentController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    def index
      consented_clients = client_source.where.not(consent_form_signed_on: nil)
      unconfirmed = consented_clients.where(housing_release_status: [nil, ''])
      confirmed = consented_clients.where.not(housing_release_status: [nil, ''])
      # Consent has expired when `column` falls before `expired_at`; Indefinite consent has no such date.
      # A NULL `column` (a signed form awaiting confirmation has no expiration date yet) never counts as expired.
      column, expired_at = case client_source.release_duration
      when 'Use Expiration Date'
        [c_t[:consent_expires_on], Date.current]
      when 'One Year', 'Two Years'
        [c_t[:consent_form_signed_on], client_source.consent_validity_period.ago.to_date]
      end
      if column
        @expired_clients = unconfirmed.where(column.lt(expired_at)).preload(:user_clients)
        @expiring_clients = confirmed.where(column.between(expired_at...expired_at + 30.days)).preload(:user_clients)
        @unconfirmed = unconfirmed.where(column.gteq(expired_at).or(column.eq(nil))).preload(:user_clients)
      else
        @expired_clients = []
        @expiring_clients = []
        @unconfirmed = unconfirmed.preload(:user_clients)
      end
      # These exist in a different database, so we'll need to fetch them separately
      @users = (@expired_clients + @expiring_clients).map do |client|
        users = User.where(id: client.user_clients.non_confidential.active.pluck(:user_id))
        [client.id, users]
      end.to_h
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end
