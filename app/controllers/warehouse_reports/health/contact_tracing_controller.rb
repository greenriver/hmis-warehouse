###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Health
  class ContactTracingController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_edit_health_emergency_contact_tracing!
    before_action :load

    def index
      @by_case = {
        contacts: @contacts.group_by(&:case_id),
        managers: @managers.group_by(&:case_id),
        staff: @staff.group_by(&:case_id),
      }
    end

    def load
      @ongoing = Health::Tracing::Case.ongoing
      @completed = Health::Tracing::Case.completed
      @contacts = Health::Tracing::Contact.all
      @managers = Health::Tracing::SiteLeader.all
      @staff = Health::Tracing::Staff.all
    end
  end
end
