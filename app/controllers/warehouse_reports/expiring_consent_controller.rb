###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class ExpiringConsentController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    def index
      consented_clients = client_source.where.not(consent_form_signed_on: nil)
      @expired_clients = []
      @expiring_clients = []
      if client_source.release_duration != 'Indefinite'
        @expired_clients = consented_clients.
          where(housing_release_status: [nil, '']).
          where(c_t[:consent_form_signed_on].lt(client_source.consent_validity_period.ago.to_date)).
          preload(:user_clients)
        @expiring_clients = consented_clients.where.not(housing_release_status: [nil, '']).
          where(c_t[:consent_form_signed_on].lt(client_source.consent_validity_period.ago + 30.days)).
          preload(:user_clients)
      end
      @unconfirmed = consented_clients.where(housing_release_status: [nil, '']).
        where(c_t[:consent_form_signed_on].gteq(client_source.consent_validity_period.ago.to_date)).
        preload(:user_clients)
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
