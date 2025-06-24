# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require_relative '../../../config/deploy/docker/lib/asset_compiler'

module Admin
  class ThemesController < ApplicationController
    before_action :require_can_edit_theme!

    def edit
      @theme = GrdaWarehouse::Theme.where(client: ENV.fetch('CLIENT')).first_or_create
      @theme.set_theme_default_css!
      @theme.set_theme_default_logo!
      @theme.set_theme_default_print_logo!
    end

    def update
      @theme = GrdaWarehouse::Theme.where(client: ENV.fetch('CLIENT')).first
      @theme.update(allowed_params)
      @theme.logo.attach(allowed_params[:logo]) if allowed_params[:logo].present?
      @theme.print_logo.attach(allowed_params[:print_logo]) if allowed_params[:print_logo].present?
      respond_with(@theme, location: edit_admin_theme_path)
    end

    def allowed_params
      params.require(:theme).permit(
        :client,
        :css_file_contents,
        :hmis_origin,
        :hmis_value,
        :logo,
        :print_logo,
        :careplan_logo,
      )
    end

    def flash_interpolation_options
      { resource_name: 'Theme' }
    end
  end
end
