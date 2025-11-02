###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Users::SessionsController < ApplicationController
  skip_before_action :authenticate_user!
  def index
    if current_user.present?
      redirect_to(current_user.my_root_path)
    else
      flash.now.alert = I18n.t('views.session.invalid_user') if request.headers['HTTP_X_FORWARDED_USER'].present?
      render :index
    end
  end

  def sign_in
    url = idp_login_link(params[:connector_id])
    redirect_to url, allow_other_host: true
  end

  def sign_out
    redirect_to '/oauth2/sign_out'
  end

  # This requires alpha config for oauth2-proxy
  # and may break if config options change in the future
  def idp_login_link(connector_id = nil, **args)
    auth_start_path = 'oauth2/start'
    auth_start_url = "#{root_url}#{auth_start_path}"

    query = args || {}
    query[:connector_id] = connector_id if connector_id.present?

    return auth_start_url if query.blank?

    "#{auth_start_url}?#{URI.encode_www_form(query)}"
  end
end
