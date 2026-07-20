###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class PublicFilesController < ApplicationController
    before_action :require_can_manage_config!

    def index
      @files = file_source.order(id: :desc).
        select(:id, :name, :created_at)
      @pagy, @files = pagy(@files)
      @file = file_source.new
    end

    def create
      file = file_params[:file]
      content = file&.read
      content_type = Marcel::MimeType.for(content, name: file&.original_filename) if file
      @file = file_source.create(file_params.merge(user_id: current_user.id, content: content, content_type: content_type, size: file&.size, file: file&.original_filename))
      if @file.invalid?
        flash[:error] = @file.errors.full_messages.join('; ') + params.inspect.to_s
        redirect_to admin_public_files_path
        return
      end
      respond_with @file, location: admin_public_files_path
    end

    def destroy
      @file = file_source.find(params[:id].to_i)
      @file.destroy
      respond_with @file, location: admin_public_files_path
    end

    private def file_params
      params.require(:grda_warehouse_public_file).permit(
        :file,
        :name,
      )
    end

    def file_source
      GrdaWarehouse::PublicFile
    end

    def flash_interpolation_options
      { resource_name: 'Public File' }
    end
  end
end
