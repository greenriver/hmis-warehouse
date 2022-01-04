###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class SourceClientsController < ApplicationController
  include AjaxModalRails::Controller
  include ClientPathGenerator

  before_action :require_can_create_clients!, except: [:image]
  before_action :set_client
  before_action :set_destination_client
  after_action :log_client, except: [:image]

  def edit
  end

  def update
    clean_params = client_params
    if can_view_full_ssn?
      clean_params[:SSN] = clean_params[:SSN].gsub(/\D/, '')
    else
      clean_params[:SSN] = @client.SSN
    end
    valid_params = validate_new_client_params(clean_params)
    clean_params = clean_params.to_h.with_indifferent_access
    # Reset gender columns
    HUD.gender_id_to_field_name.values.uniq.each do |g|
      clean_params[g] = nil
    end

    clean_params[:Gender]&.each do |k|
      next if k.blank?

      gender_column = HUD.gender_id_to_field_name[k.to_i]
      clean_params[gender_column] = 1
    end
    clean_params.delete(:Gender)

    if valid_params
      @client.update(clean_params)
      # also update the destination client, we're assuming this is authoritative
      # for this bit of data
      @destination_client.update(clean_params)
      flash[:notice] = 'Client saved successfully'
      client_source.clear_view_cache(@destination_client.id)
      redirect_to redirect_to_path
    else
      flash[:error] = 'Unable to save client'
      render action: :edit
    end
  end

  def image
    max_age = if request.headers['Cache-Control'].to_s.include? 'no-cache'
      0
    else
      30.minutes
    end
    response.headers['Last-Modified'] = Time.zone.now.httpdate
    expires_in max_age, public: false
    image = @client.image_for_source_client(max_age)
    # NOTE: The test environment is really unhappy when there's no image
    if image && ! Rails.env.test?
      send_data image, type: MimeMagic.by_magic(image), disposition: 'inline'
    else
      head(:forbidden)
      nil
    end
  end

  def destination
    redirect_to redirect_to_path
  end

  private def redirect_to_path
    client_path(@destination_client)
  end

  private def set_client
    @client = client_source.find(params[:id].to_i)
  end

  private def set_destination_client
    @destination_client = @client.destination_client
  end

  private def client_params
    params.require(:client).
      permit(
        :SSN,
        :DOB,
        :FirstName,
        :MiddleName,
        :LastName,
        :VeteranStatus,
        :Female,
        :Male,
        Gender: [],
      )
  end

  private def client_source
    GrdaWarehouse::Hud::Client
  end

  private def validate_new_client_params(clean_params)
    valid = true
    unless [0, 9].include?(clean_params[:SSN].to_s.length)
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
    valid
  end
end
