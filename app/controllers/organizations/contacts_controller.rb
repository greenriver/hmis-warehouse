###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Organizations
  class ContactsController < ApplicationController
    include Contacts
    include PjaxModalController

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
