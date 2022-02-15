###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class AvailableFileTagsController < ApplicationController
    before_action :require_can_manage_config!
    before_action :set_available_file_tag, only: [:destroy]

    respond_to :html

    def index
      @available_file_tags = GrdaWarehouse::AvailableFileTag.ordered
      respond_with(@available_file_tags)
    end

    def new
      @available_file_tag = GrdaWarehouse::AvailableFileTag.new
      @form_url = admin_available_file_tags_path
      respond_with(@available_file_tag)
    end

    def edit
      @available_file_tag = GrdaWarehouse::AvailableFileTag.find(params[:id].to_i)
      @form_url = admin_available_file_tag_path(@available_file_tag)
      respond_with(@available_file_tag)
    end

    def update
      @available_file_tag = GrdaWarehouse::AvailableFileTag.find(params[:id].to_i)
      @available_file_tag.update(available_file_tag_params)
      respond_with(@available_file_tag, location: admin_available_file_tags_path)
    end

    def create
      @available_file_tag = GrdaWarehouse::AvailableFileTag.create!(available_file_tag_params)
      respond_with(@available_file_tag, location: admin_available_file_tags_path)
    end

    def destroy
      @available_file_tag.destroy
      respond_with(@available_file_tag, location: admin_available_file_tags_path)
    end

    def flash_interpolation_options
      { resource_name: 'Tag' }
    end

    private

    def set_available_file_tag
      @available_file_tag = GrdaWarehouse::AvailableFileTag.find(params[:id])
    end

    def available_file_tag_params
      params.require(:available_file_tag).permit(
        :name,
        :group,
        :included_info,
        :weight,
        :note,
        :consent_form,
        :verified_homeless_history,
        :notification_trigger,
        :document_ready,
        :requires_effective_date,
        :requires_expiration_date,
        :required_for,
        :coc_available,
        :full_release,
      )
    end
  end
end
