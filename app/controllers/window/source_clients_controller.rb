module Window
  class SourceClientsController < ApplicationController
    include PjaxModalController
    include WindowClientPathGenerator
    
    before_action :require_can_create_clients!
    before_action :set_client
    before_action :set_destination_client

    def edit

    end

    def update
      clean_params = client_params
      clean_params[:SSN] = clean_params[:SSN].gsub(/\D/, '')
      valid_params = validate_new_client_params(clean_params)
      if valid_params
        @client.update(clean_params)
        # also update the destination client, we're assuming this is authoritative 
        # for this bit of data
        @destination_client.update(clean_params)
        flash[:notice] = "Client saved successfully"
        client_source.clear_view_cache(@destination_client.id)
        redirect_to redirect_to_path
      else
        flash[:error] = 'Unable to save client'
        render action: :edit
      end
      
    end

    def redirect_to_path
      window_client_path(@destination_client)
    end

    def set_client
      @client = client_source.find(params[:id].to_i)
    end

    def set_destination_client
      @destination_client = @client.destination_client
    end

    def client_params
      params.require(:client).
        permit(
          :SSN,
          :DOB,
          :FirstName,
          :MiddleName,
          :LastName,
          :Gender,
          :VeteranStatus
        )
    end
    def client_source
      GrdaWarehouse::Hud::Client
    end

    def validate_new_client_params(clean_params)
      valid = true
      unless [0,9].include?(clean_params[:SSN].length)
        @client.errors[:SSN] = 'SSN must contain 9 digits'
        valid = false
      end
      if clean_params[:FirstName].blank?
        @client.errors[:FirstName] = 'First name is required'
        valid = false
      end
      if clean_params[:LastName].blank?
        @client.errors[:LastName] = 'Last name is required'
        valid = false
      end
      if clean_params[:DOB].blank?
        @client.errors[:DOB] = 'Date of birth is required'
        valid = false
      end
      valid
    end
  end
end