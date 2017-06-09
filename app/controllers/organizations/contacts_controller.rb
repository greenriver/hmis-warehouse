module Organizations
  class ContactsController < ApplicationController
    include Contacts
    
    
    def contact_source
      GrdaWarehouse::Contact::Organization
    end

    def set_entity
      @entity = organization_scope.find(params[:organization_id].to_i)
    end

    def organization_scope
      GrdaWarehouse::Hud::Organization
    end

  end
end