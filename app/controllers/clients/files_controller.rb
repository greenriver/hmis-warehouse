module Clients
  class FilesController < Window::Clients::FilesController
    include ClientPathGenerator
    skip_before_action :require_can_manage_window_client_files!
    before_action :require_can_manage_client_files!
    
    def file_scope
      file_source.where(client_id: @client.id)
    end
  end
end
