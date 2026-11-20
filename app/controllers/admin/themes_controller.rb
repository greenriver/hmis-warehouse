###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class ThemesController < ApplicationController
    before_action :require_can_edit_theme!

    def edit
      @theme = GrdaWarehouse::Theme.where(client: ENV.fetch('CLIENT')).first_or_create
      @theme.set_theme_default_css!
      @theme.set_theme_default_logo!
      @theme.set_theme_default_print_logo!
      @theme.set_theme_default_hmis_logo!
    end

    def update
      @theme = GrdaWarehouse::Theme.where(client: ENV.fetch('CLIENT')).first
      @theme.update(allowed_params)
      # A rejected upload must not drive the "current logo" previews on the re-rendered form
      @theme.attachment_changes.clear if @theme.errors.any?
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
        :hmis_logo,
      )
    end

    def flash_interpolation_options
      { resource_name: 'Theme' }
    end
  end
end
