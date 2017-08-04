module Clients
  class FilesController < Window::Clients::FilesController
    include ClientPathGenerator
    
    def create
      @file = file_source.new
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
        )
        @file.save!
      rescue Exception => e
        flash[:error] = e.message
        render action: :new
        return
      end
      redirect_to action: :index 
    end
    
    def file_scope
      file_source.where(client_id: @client.id)
    end
    
    def require_can_manage_these_client_files!
      require_can_manage_client_files!
    end
  end
end
