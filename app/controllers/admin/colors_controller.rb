###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class ColorsController < ApplicationController
    before_action :require_can_edit_theme!
    before_action :set_all_colors

    def edit
    end

    def update
      batch = @colors.map do |slug, color|
        color.background_color = allowed_params[slug]
        color
      end
      GrdaWarehouse::SystemColor.import(
        batch,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: [:background_color],
        },
      )
      respond_with(batch.first, location: edit_admin_color_path)
    end

    def allowed_params
      params.require(:colors)
    end

    private def set_all_colors
      @colors = GrdaWarehouse::SystemColor.all.index_by(&:slug)
    end

    def flash_interpolation_options
      { resource_name: 'System Color' }
    end
  end
end
