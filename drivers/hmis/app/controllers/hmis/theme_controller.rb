###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Controller for dynamically changing the HMIS theme.
# This is currently only used for QA/dev purposes, to allow
# dynamically switching out the theme from the browser console.
# The default theme is fetched from AppSettingsController.
class Hmis::ThemeController < Hmis::BaseController
  skip_before_action :authenticate_user!
  prepend_before_action :skip_timeout

  def index
    render json: GrdaWarehouse::Theme.find_by(id: params[:id])&.hmis_value || {}
  end

  def list
    themes = GrdaWarehouse::Theme.where.not(hmis_value: nil).pluck(:id, :client).map do |id, client|
      { id: id, client: client }
    end
    render json: themes
  end
end
