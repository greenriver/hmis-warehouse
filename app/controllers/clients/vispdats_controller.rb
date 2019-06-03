###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

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
