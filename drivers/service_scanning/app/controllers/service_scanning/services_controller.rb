###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning
  class ServicesController < ApplicationController
    include AjaxModalRails::Controller
    include ClientController
    include ClientPathGenerator
    before_action :require_can_view_clients!
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
      @show_new_client_form = query.present? && ::GrdaWarehouse::DataSource.authoritative.scannable && can_create_clients?
      return unless query

      @search_results = client_source.
        text_search(
          query,
          client_scope: client_search_scope,
        ).
        order(LastName: :asc, FirstName: :asc)
      @pagy, @search_results = pagy(@search_results)
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
          @service.save!
          respond_with(@service, location: service_scanning_services_path(service: index_params.merge(client_id: client.id, service_id: @service.id)))
        else
          flash[:error] = 'Unable to add service.'
          redirect_to(service_scanning_services_path(service: index_params.merge(autofocus: :project_id)))
        end
        return
      end

      scanner_id = options[:scanner_id]
      if scanner_id.blank?
        flash[:error] = 'An ID or search term is required.'
        redirect_to(service_scanning_services_path(service: index_params))
      elsif scanner_id.match?(/^[a-z]*(\d+)$/i)
        # If the submission looks like a scan card (some number of letters followed by numbers)
        handle_id_search(scanner_id, options)
      else
        # we need to conduct at client search
        redirect_to(service_scanning_services_path(service: index_params.merge(q: scanner_id)))
      end
    end

    def update
      service = ServiceScanning::Service.find(params[:id].to_i)
      service_note = note_params[:service_note]
      @note = ::GrdaWarehouse::ClientNotes::ServiceNote.create(
        client_id: service.client_id,
        user_id: current_user.id,
        note: service_note,
        service_id: service.id,
        project_id: service.project_id,
      )
      if @note.valid?
        respond_with(@note, location: service_scanning_services_path(service: index_params.merge(client_id: service.client_id, service_id: service.id)))
      else
        flash[:error] = "Note can't be empty"
        redirect_to(service_scanning_services_path(service: index_params.merge(client_id: service.client_id, service_id: service.id)))
      end
    end

    def new_client
      @client = client_source.new
    end

    # Copied and modified from ClientController
    def create_client
      unless ::GrdaWarehouse::DataSource.authoritative.scannable.exists?
        flash[:error] = 'No Scannable Data Source Found'
        redirect_to(service_scanning_services_path(service: index_params))
        return
      end

      clean_params = client_create_params
      clean_params[:SSN] = clean_params[:SSN].gsub(/\D/, '')

      # If we only have one scannable data source, we don't bother sending it, just use it
      clean_params[:data_source_id] ||= ::GrdaWarehouse::DataSource.authoritative.scannable.first.id
      @client = client_source.new(clean_params)

      params_valid = validate_new_client_params(clean_params)

      @existing_matches ||= []
      if ! params_valid
        flash[:error] = 'Unable to create client'
        render action: :new_client
      else
        # Create a new source and destination client
        # and redirect to the search page
        client_source.transaction do
          destination_ds_id = ::GrdaWarehouse::DataSource.destination.first.id
          @client.save
          @client.update(PersonalID: @client.id)

          destination_client = client_source.new(clean_params.
            merge(
              data_source_id: destination_ds_id,
              PersonalID: @client.id,
              creator_id: current_user.id,
            ))
          destination_client.save

          warehouse_client = ::GrdaWarehouse::WarehouseClient.create(
            id_in_source: @client.id,
            source_id: @client.id,
            destination_id: destination_client.id,
            data_source_id: @client.data_source_id,
          )
          unless request.xhr?
            if @client.persisted? && destination_client.persisted? && warehouse_client.persisted?
              flash[:notice] = "Client #{@client.full_name} created."
              after_create_path = client_path_generator
              if @client.data_source.after_create_path.present?
                after_create_path += [@client.data_source.after_create_path]
                redirect_to polymorphic_path(after_create_path, client_id: destination_client.id)
              else
                redirect_to polymorphic_path(after_create_path, id: destination_client.id)
              end
            else
              flash[:error] = 'Unable to create client'
              render action: :new_client
            end
          end
        end
      end
    end

    def validate_new_client_params(clean_params)
      valid = true
      unless [0, 9].include?(clean_params[:SSN].length)
        @client.errors.add(:SSN, :format, message: 'must contain 9 digits')
        valid = false
      end
      if clean_params[:FirstName].blank?
        @client.errors.add(:FirstName, :required, message: 'is required')
        valid = false
      end
      if clean_params[:LastName].blank?
        @client.errors.add(:LastName, :required, message: 'is required')
        valid = false
      end
      if clean_params[:DOB].blank?
        @client.errors.add(:DOB, :required, message: 'Date of birth is required')
        valid = false
      end
      valid
    end

    def destroy
      @service = ServiceScanning::Service.find(params[:id].to_i)
      @service.destroy
      respond_with(@service, location: service_scanning_services_path(service: index_params))
    end

    private def handle_id_search(scanner_id, _options)
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

    private def note_params
      return {} unless params[:note]

      params.require(:note).permit(
        :service_note,
      )
    end

    def client_create_params
      params.require(:client).
        permit(
          :FirstName,
          :MiddleName,
          :LastName,
          :SSN,
          :DOB,
          :Gender,
          :VeteranStatus,
          :data_source_id,
        )
    end

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
        merge(
          ::GrdaWarehouse::EtoQaaws::ClientLookup.where(
            participant_site_identifier: id,
            data_source_id: data_source_id,
          ),
        ).
        first
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

    def flash_interpolation_options
      { resource_name: 'Service' }
    end
  end
end
