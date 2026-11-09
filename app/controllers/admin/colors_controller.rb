###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class ColorsController < ApplicationController
    before_action :require_can_edit_theme!
    before_action :set_all_colors

    def edit
    end

    def update
      submitted = allowed_params
      batch = @colors.slice(*submitted.keys).map do |slug, color|
        value = submitted[slug]
        color.background_color = value.is_a?(String) ? value : nil
        color
      end
      # import skips invalid rows without raising, so check the whole batch first
      unless batch.all?(&:valid?)
        flash[:error] = 'Colors must be hex values such as #1a2b3c; no changes were saved.'
        redirect_to edit_admin_color_path
        return
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
