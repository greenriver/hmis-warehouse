###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Clients
  class EnrollmentHistoryController < ApplicationController
    include ClientController
    include ClientPathGenerator
    include ClientDependentControllers
    include ClientShowPages

    before_action :require_can_edit_clients!
    before_action :set_client
    after_action :log_client

    def index
      @date = params.dig(:history, :date)&.to_date || Date.yesterday
      @histories = history_scope.where(on: @date)
      @available_dates = history_scope.distinct.order(on: :desc).pluck(:on)
    end

    private

    def set_client
      @client = destination_searchable_client_scope.find(params[:id].to_i)
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def history_source
      GrdaWarehouse::EnrollmentChangeHistory
    end

    def history_scope
      history_source.where(client_id: @client.id)
    end

    def title_for_show
      "#{@client.name} - Historical Enrollments"
    end
  end
end
