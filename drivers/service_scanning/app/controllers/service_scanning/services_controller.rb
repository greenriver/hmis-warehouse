###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning
  class ServicesController < ApplicationController
    include PjaxModalController
    before_action :require_can_view_client_window!
    before_action :require_can_use_service_register!

    def index
      options = index_params

      klass = ServiceScanning::Service.type_from_key(options&.dig(:slug))
      @service = klass.new(options&.except(:slug))
      client_id = params.dig(:service, :client_id)
      @last_client = ::GrdaWarehouse::Hud::Client.find(client_id) if client_id
      service_id = params.dig(:service, :service_id)
      @last_service = ServiceScanning::Service.find(service_id) if service_id
      @no_client_found = params.dig(:service, :no_client).present?
    end

    def create
      options = service_params
      klass = ServiceScanning::Service.type_from_key(options[:slug])
      client = attempt_to_find_client(options[:scanner_id])

      if client.blank?
        redirect_to(service_scanning_services_path(service: index_params.merge(no_client: true)))
        return
      else
        options[:user_id] = current_user.id
        options[:client_id] = client.id
        @service = klass.create(options)
      end

      respond_with(@service, location: service_scanning_services_path(service: index_params.merge(client_id: client.id, service_id: @service.id)))
    end

    def destroy
      @service = ServiceScanning::Service.find(params[:id].to_i)
      @service.destroy
      respond_with(@service, location: service_scanning_services_path(service: index_params))
    end

    private def service_params
      return {} unless params[:service]

      params.require(:service).permit(
        :scanner_id,
        :project_id,
        :client_id,
        :slug,
        :other_type,
        :provided_at,
        :note,
      )
    end

    private def index_params
      return {} unless params[:service]

      params.require(:service).permit(
        :project_id,
        :slug,
        :other_type,
        :scanner_id,
        :provided_at,
      )
    end

    private def attempt_to_find_client(scanner_id)
      client = client_from_scanner_ids(scanner_id)
      return client if client

      client = client_from_hmis_clients(scanner_id)
      if client
        ServiceScanning::ScannerId.create(
          client_id: client.id,
          scanned_id: scanner_id,
          source_type: 'GrdaWarehouse::EtoQaaws::ClientLookup',
        )
        return client
      end
      nil
    end

    private def client_from_scanner_ids(id)
      ::GrdaWarehouse::Hud::Client.joins(:service_scanning_scanner_ids).
        merge(ServiceScanning::ScannerId.where(scanned_id: id)).
        first
    end

    private def client_from_hmis_clients(id)
      ::GrdaWarehouse::Hud::Client.joins(:source_eto_client_lookups).
        merge(::GrdaWarehouse::EtoQaaws::ClientLookup.where(participant_site_identifier: id)).
        first
    end

    def flash_interpolation_options
      { resource_name: 'Service' }
    end
  end
end
