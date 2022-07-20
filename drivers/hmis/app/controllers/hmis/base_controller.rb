###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::BaseController < ApplicationController
  include Hmis::Concerns::JsonErrors
  respond_to :json
  before_action :set_csrf_cookie
  protect_from_forgery with: :reset_session

  private def set_csrf_cookie
    cookies['CSRF-Token'] = form_authenticity_token
  end

  def authenticate_user!
    authenticate_hmis_user!
  end

  def attach_data_source_id
    domain = URI.parse(request.origin).host
    data_source_id = GrdaWarehouse::DataSource.hmis.where(hmis: domain).pluck(:id).first
    current_hmis_user.hmis_data_source_id = data_source_id
  end
end
