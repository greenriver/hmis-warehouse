module Clients
  class FilesController < Window::Clients::FilesController
    include ClientPathGenerator
    
    def destroy
      @file = file_source.find(params[:id].to_i)

      begin
        @file.destroy!
        flash[:notice] = "File was successfully deleted."
      rescue Exception => e
        flash[:error] = "File could not be deleted."
      end
      redirect_to files_path(@file.client)
    end
    
    def set_client
      @client = client_scope.find(params[:id].to_i)
    end
    
    def set_file
      @file = file_scope.find(params[:id].to_i)
    end
    
    def file_scope
      file_source.where(client_id: @client.id)
    end
  end
end
