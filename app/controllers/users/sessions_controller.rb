###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Users::SessionsController < ApplicationController
  # Skip authentication for these actions since they're handled by OAuth2-proxy
  skip_before_action :authenticate_user!, only: [:new, :create, :keepalive]

  # GET /users/sign_in
  # With JWT auth, login is handled by OAuth2-proxy
  def new
    redirect_to helpers.oauth2_sign_in_path
  end

  # POST /users/sign_in
  # With JWT auth, login is handled by OAuth2-proxy
  def create
    redirect_to helpers.oauth2_sign_in_path
  end

  # DELETE /users/sign_out
  def destroy
    request.env['last_user'] = current_user
    # Redirect to OAuth2-proxy sign out
    redirect_to '/oauth2/sign_out'
  end

  def keepalive
    head :ok
  end

  # override devise to add 'allow_other_host: true' so we can redirect to okta or superset
  def respond_to_on_destroy
    respond_to do |format|
      format.all { head :no_content }
      format.any(*navigational_formats) do
        redirect_to(
          after_sign_out_path_for(resource_name),
          status: :see_other,
          allow_other_host: true,
        )
      end
    end
  end

  private

  def resource_name
    :user
  end

  def navigational_formats
    [:html]
  end
end
