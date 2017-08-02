module Clients
  class FilesController < Window::Clients::FilesController
    include ClientPathGenerator
    
    def create
      file = file_params["file"]
      @file = @client.client_files.create(file_params.merge({
        user_id: current_user.id,
        content_type: file.content_type,
        content: file.read,
        }))
      if @file.save
        flash[:notice] = _("File successfully uploaded.")
        redirect_to action: :index
      else
        flash[:alert] = _("File could not be uploaded.")
        render :new
      end
    end
    
    def file_scope
      file_source.where(client_id: @client.id)
    end
    
    def require_can_manage_these_client_files!
      require_can_manage_client_files!
    end
  end
end
