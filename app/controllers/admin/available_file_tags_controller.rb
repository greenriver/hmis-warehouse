module Admin
  class AvailableFileTagsController < ApplicationController
    before_action :require_can_manage_config!
    before_action :set_available_file_tag, only: [:destroy]

    respond_to :html

    def index
      @available_file_tags = GrdaWarehouse::AvailableFileTag.all
      respond_with(@available_file_tags)
    end

    def new
      @available_file_tag = GrdaWarehouse::AvailableFileTag.new
      respond_with(@available_file_tag)
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
        params.require(:available_file_tag).permit(:name, :group, :included_info, :weight)
      end
  end
end
