###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning
  class ScannerIdsController < ApplicationController
    include AjaxModalRails::Controller
    include ClientController
    include ClientPathGenerator
    before_action :require_can_view_clients!
    before_action :require_can_use_service_register!
    before_action :set_client, only: [:show, :destroy]

    def index
      return unless params[:q].present?

      @clients = client_source.
        text_search(
          params[:q],
          client_scope: client_search_scope,
        ).
        order(LastName: :asc, FirstName: :asc).
        page(params[:page]).per(20)
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
      options = card_params.to_h.merge(source_type: 'ManuallyAdded')
      options[:scanned_id] = options[:scanned_id].gsub(/[a-z]/i, '')
      @card = @client.service_scanning_scanner_ids.create(options)
      return if request.xhr?

      flash[:notice] = 'ID card successfully added.'
      redirect_to(service_scanning_scanner_id_path(@client))
    end

    private def client_source
      ::GrdaWarehouse::Hud::Client
    end

    # should always return a destination client, but some visibility
    # is governed by the source client, some by the destination
    private def client_scope(id: nil)
      client_source.destination_visible_to(current_user).where(id: id)
    end

    private def client_search_scope
      client_source.searchable_by(current_user)
    end

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
