module Clients
  class VispdatsController < Window::Clients::VispdatsController
    include ClientPathGenerator

    def destroy
      @vispdat.destroy
      respond_with(@vispdat, location: client_vispdats_path(@client))
    end

  end
end
