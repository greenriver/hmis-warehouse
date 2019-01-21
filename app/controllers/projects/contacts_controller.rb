module Projects
  class ContactsController < ApplicationController
    include Contacts
    include PjaxModalController

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
