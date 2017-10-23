module Clients
  class VispdatsController < Window::Clients::VispdatsController
    include ClientPathGenerator

    def upload_file
      set_vispdat
      @file = GrdaWarehouse::ClientFile.new
      begin
        file = file_params[:file]
        @file.assign_attributes(
          file: file,
          client_id: @client.id,
          user_id: current_user.id,
          content_type: file&.content_type,
          content: file&.read,
          visible_in_window: file_params[:visible_in_window],
          note: file_params[:note],
          name: file_params[:name],
          vispdat_id: @vispdat.id
        )
        @file.tag_list.add(tag_list.select(&:present?))
        @file.save!
        flash[:notice] = "File #{file_params[:name]} saved."
      rescue Exception => e
        flash[:error] = e.message
      end
      redirect_to action: :edit 
    end

    def destroy_file
      set_vispdat
      @file = @vispdat.files.find params[:file_id]
      @file.destroy
      respond_with @vispdat
    end

    def destroy
      @vispdat.destroy
      respond_with(@vispdat, location: client_vispdats_path(@client))
    end

    private

    def file_params
      params.require(:grda_warehouse_client_file).
        permit(
          :file,
          :name,
          :note,
          :visible_in_window,
          tag_list: [],
        )
    end

    def tag_list
      file_params[:tag_list] || []
    end

  end
end
