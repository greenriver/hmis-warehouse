###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class ThemesController < ApplicationController
    before_action :require_can_edit_theme!

    def edit
      @theme = GrdaWarehouse::Theme.first_or_create(client: ENV.fetch('CLIENT'))
      @theme.set_theme_defaults
    end

    def update
      @theme = GrdaWarehouse::Theme.first
      @theme.update(allowed_params)
      # If these end up taking too long, we can background them
      @theme.store_remote_css_file
      @theme.store_remote_scss_file
      # background assets:precompile
      RunAssetCompilerJob.perform_later

      respond_with(@theme, location: edit_admin_theme_path)
    end

    def allowed_params
      params.require(:theme).permit(
        :client,
        :scss_file_contents,
        :css_file_contents,
        :hmis_origin,
        :hmis_value,
      )
    end

    def flash_interpolation_options
      { resource_name: 'Theme' }
    end
  end
end
