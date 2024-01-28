###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class LinksController < ApplicationController
    before_action :require_can_edit_users!
    before_action :set_link, only: [:edit, :update, :destroy]

    def index
      @links = link_scope.order(updated_at: :desc)
      @pagy, @links = pagy(@links)
    end

    def new
      @link = link_scope.new
    end

    def create
      @link = link_scope.create(link_params)
      link_scope.invalidate_cache
      respond_with(@link, location: admin_links_path)
    end

    def edit
    end

    def update
      @link.update(link_params)
      link_scope.invalidate_cache
      respond_with(@link, location: admin_links_path)
    end

    def destroy
      @link.destroy
      link_scope.invalidate_cache
      respond_with(@link, location: admin_links_path)
    end

    def set_link
      @link = link_scope.find(params[:id].to_i)
    end

    def link_params
      params.require(:link).permit(
        :label,
        :url,
        :subject,
        :location,
      )
    end

    def link_scope
      Link
    end

    def flash_interpolation_options
      { resource_name: 'Link' }
    end
  end
end
