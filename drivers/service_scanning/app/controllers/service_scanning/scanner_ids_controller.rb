###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning
  class ScannerIdsController < ApplicationController
    include PjaxModalController
    include ClientController
    before_action :require_can_view_client_window!
    before_action :require_can_use_service_register!
    before_action :set_client, only: [:show, :destroy]

    def index
      if params[:q].present?
        @clients = client_source.text_search(
          params[:q],
          client_scope: client_search_scope
        ).
        order(LastName: :asc, FirstName: :asc).
        page(params[:page]).per(20)
      end
    end

    def show
      @scanned_ids = @client.service_scanning_scanner_ids.order(created_at: :desc)
      @card = ServiceScanning::ScannerId.new
    end

    def destroy
      @card = @client.service_scanning_scanner_ids.efind(params[:card_id])
      @card.destroy
      respond_with(@card, location: service_scanning_scanner_id_path(@client))
    end

    def create
      params[:id] = params[:card][:id].to_i
      set_client
      # @client = client_source.searchable_by(current_user).find(params[:card][:id].to_i)
      @card = @client.service_scanning_scanner_ids.create(card_params.merge(source_type: 'ManuallyAdded'))

      respond_with(@card, location: service_scanning_scanner_id_path(@client)) unless request.xhr?
    end

    private def client_source
      ::GrdaWarehouse::Hud::Client
    end

    # should always return a destination client, but some visibility
    # is governed by the source client, some by the destination
    private def client_scope(id: nil)
      client_source.destination.where(
        Arel.sql(
          client_source.arel_table[:id].in(visible_by_source(id: id)).
          or(client_source.arel_table[:id].in(visible_by_destination(id: id))).to_sql,
        ),
      )
    end

    private def visible_by_source(id: nil)
      query = ::GrdaWarehouse::WarehouseClient.joins(:source).
        merge(client_source.viewable_by(current_user))
      query = query.where(destination_id: id) if id.present?

      Arel.sql(query.select(:destination_id).to_sql)
    end

    private def visible_by_destination(id: nil)
      query = client_source.viewable_by(current_user)
      query = query.where(id: id) if id.present?

      Arel.sql(query.select(:id).to_sql)
    end

    private def client_search_scope
      client_source.searchable_by(current_user)
    end

    # private def set_client
    #   @client = client_source.searchable_by(current_user).find(params[:id].to_i)
    # end

    private def card_params
      params.require(:card).permit(
        :scanned_id,
      )
    end

    def flash_interpolation_options
      { resource_name: 'Scan Card ID' }
    end
  end
end
