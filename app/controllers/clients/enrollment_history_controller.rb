###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Clients
  class EnrollmentHistoryController < ApplicationController
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :require_can_edit_clients!
    before_action :set_client
    after_action :log_client

    def index
      @date = begin
                params[:history][:date].to_date
              rescue StandardError
                Date.yesterday
              end
      @histories = history_scope.where(on: @date)
      @available_dates = history_scope.distinct.order(on: :desc).pluck(:on)
    end

    private

    def set_client
      @client = searchable_client_scope.find(params[:id].to_i)
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
