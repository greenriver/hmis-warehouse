###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Organizations
  class ContactsController < ApplicationController
    include Contacts
    include AjaxModalRails::Controller

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
