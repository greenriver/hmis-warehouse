###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning
  class ServicesController < ApplicationController
    include PjaxModalController
    include ClientController
    include ClientPathGenerator
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
      query = params.dig(:service, :q)
      if query
        @search_results = client_source.text_search(
          query,
          client_scope: client_search_scope
        ).
        order(LastName: :asc, FirstName: :asc).
        page(params[:page]).per(20)
      end
    end

    def create
      options = service_params.merge(user_id: current_user.id)
      klass = ServiceScanning::Service.type_from_key(options[:slug])

      # Some Error Checking
      if klass.blank?
        flash[:error] = 'Unknown Service Type.'
        redirect_to(service_scanning_services_path(service: index_params.merge(autofocus: :project_id)))
        return
      end

      @service = klass.new(options)
      if @service.project.blank?
        flash[:error] = 'A project is required.'
        redirect_to(service_scanning_services_path(service: index_params.merge(autofocus: :project_id)))
        return
      end

      # If we have a valid client ID, we don't need to bother with the scanner IDs
      if @service.client_id.present?
        client = @service.client
        if client.present?
          @service.save!(options)
          respond_with(@service, location: service_scanning_services_path(service: index_params.merge(client_id: client.id, service_id: @service.id)))
          return
        else
          flash[:error] = 'Unable to add service.'
          redirect_to(service_scanning_services_path(service: index_params.merge(autofocus: :project_id)))
          return
        end
      end

      scanner_id = options[:scanner_id]
      if scanner_id.blank?
        flash[:error] = 'An ID or search term is required.'
        redirect_to(service_scanning_services_path(service: index_params))
        return
      elsif scanner_id.match?(/^[a-z]*(\d+)$/i)
        # If the submission looks like a scan card (some number of letters followed by numbers)
        handle_id_search(scanner_id, options)
      else
        # we need to conduct at client search
        redirect_to(service_scanning_services_path(service: index_params.merge(q: scanner_id)))
        return
      end
    end

    def destroy
      @service = ServiceScanning::Service.find(params[:id].to_i)
      @service.destroy
      respond_with(@service, location: service_scanning_services_path(service: index_params))
    end

    private def handle_id_search(scanner_id, options)
      numeric_id = scanner_id.gsub(/^[a-z]*/i, '')
      client = attempt_to_find_client(numeric_id, @service.project.data_source_id)

      if client.blank?
        redirect_to(service_scanning_services_path(service: index_params.merge(no_client: true)))
        return
      else
        @service.client_id = client.id
        @service.save!
      end

      respond_with(@service, location: service_scanning_services_path(service: index_params.merge(client_id: client.id, service_id: @service.id)))
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
    helper_method :index_params

    private def attempt_to_find_client(scanner_id, data_source_id)
      client = client_from_scanner_ids(scanner_id)
      return client if client

      client = client_from_hmis_clients(scanner_id, data_source_id)
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

    private def client_from_hmis_clients(id, data_source_id)
      ::GrdaWarehouse::Hud::Client.joins(:source_eto_client_lookups).
        merge(::GrdaWarehouse::EtoQaaws::ClientLookup.where(
          participant_site_identifier: id,
          data_source_id: data_source_id,
        )).
        first
    end

    private def client_source
      ::GrdaWarehouse::Hud::Client
    end

    # should always return a destination client, but some visibility
    # is governed by the source client, some by the destination
    private def client_scope(id: nil)
      client_source.client_source.destination_client_viewable_by_user(client_id: id, user: current_user)
    end

    private def client_search_scope
      client_source.searchable_by(current_user)
    end

    def flash_interpolation_options
      { resource_name: 'Service' }
    end
  end
end
