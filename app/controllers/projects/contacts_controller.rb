###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Projects
  class ContactsController < ApplicationController
    include Contacts
    include AjaxModalRails::Controller

    def contact_source
      GrdaWarehouse::Contact::Project
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def set_entity
      @entity = project_source.find(params[:project_id].to_i)
    end
  end
end
