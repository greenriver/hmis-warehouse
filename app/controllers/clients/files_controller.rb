module Clients
  class FilesController < Window::Clients::FilesController
    include ClientPathGenerator
    
    def file_scope
      file_source.where(client_id: @client.id)
    end
    
    def require_can_manage_these_client_files!
      require_can_manage_client_files!
    end
  end
end
