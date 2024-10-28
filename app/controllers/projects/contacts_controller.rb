###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
      not_authorized! unless current_user.policy_for(@entity, type: :project).can_view_clients?
    end
  end
end
