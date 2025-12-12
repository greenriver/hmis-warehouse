###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class ContentPagesController < ApplicationController
    before_action :require_can_manage_config!
    before_action :set_page, only: [:show, :edit, :update, :destroy]

    def index
      @pages = page_scope.ordered
      @pagy, @pages = pagy(@pages)
    end

    def show
      redirect_to edit_admin_content_page_path(@page)
    end

    def new
      @page = page_scope.new
    end

    def create
      @page = page_scope.new(page_params.merge(updated_by: current_user))

      if @page.save
        redirect_to admin_content_pages_path, notice: 'Content page created.'
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @page.update(page_params.merge(updated_by: current_user))
        redirect_to admin_content_pages_path, notice: 'Content page updated.'
      else
        render :edit
      end
    end

    def destroy
      if @page.compliance_requirements.exists?
        redirect_to admin_content_pages_path, alert: 'Cannot delete page linked to a compliance requirement.'
      else
        @page.destroy
        redirect_to admin_content_pages_path, notice: 'Content page deleted.'
      end
    end

    private

    def page_scope
      GrdaWarehouse::ContentPage.all
    end

    def set_page
      @page = page_scope.find_by!(slug: params[:id])
    end

    def page_params
      params.require(:content_page).permit(:slug, :title, :content)
    end
  end
end
