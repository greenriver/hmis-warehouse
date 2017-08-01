module Clients
  class FilesController < Window::Clients::FilesController
    include ClientPathGenerator
    
    def file_scope
      file_source.where(client_id: @client.id)
    end
  end
end
