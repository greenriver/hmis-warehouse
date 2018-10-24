module Clients
  class VispdatsController < Window::Clients::VispdatsController
    include ClientPathGenerator

    before_action :require_can_edit_vspdat!
    after_action :log_client

    def destroy
      @vispdat.disassociate_files
      @vispdat.destroy
      respond_with(@vispdat, location: client_vispdats_path(@client))
    end

  end
end
