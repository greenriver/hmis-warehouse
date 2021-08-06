###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class ContactTracingController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_edit_health_emergency_contact_tracing!
    before_action :load_cases, except: [:single_case]
    before_action :load_case, only: [:single_case]
    before_action :load_by_case

    def index
      @paginated = @cases.page(params[:page]).per(25)
    end

    def download
      render xlsx: 'download', filename: "Contact Tracing #{Date.current}.xlsx"
    end

    def single_case
      render xlsx: 'download', filename: "#{@case.name}.xlsx"
    end

    def index_case_columns
      @index_case_columns ||= Health::Tracing::Case.index_case_columns
    end
    helper_method :index_case_columns

    def index_cases
      @index_cases ||= @cases.map(&:to_h)
    end
    helper_method :index_cases

    def patient_contact_columns
      @patient_contact_columns ||= Health::Tracing::Contact.patient_contact_columns
    end
    helper_method :patient_contact_columns

    def patient_contacts
      @patient_contacts ||= @contacts.map(&:to_h)
    end
    helper_method :patient_contacts

    def site_manager_columns
      @site_manager_columns ||= Health::Tracing::SiteLeader.site_manager_columns
    end
    helper_method :site_manager_columns

    def site_managers
      @site_managers ||= @managers.map do |manager|
        {
          investigator: manager.investigator,
          index_case_id: manager.case_id.to_s,
          site: manager.site_name,
          site_leader: manager.site_leader_name,
          notification_date: manager.contacted_on&.strftime('%m/%d/%Y'),
        }
      end
    end
    helper_method :site_managers

    def staff_contacts_columns
      @staff_contacts_columns ||= Health::Tracing::Staff.staff_contacts_columns
    end
    helper_method :staff_contacts_columns

    def staff_contacts
      @staff_contacts ||= @staff.map(&:to_h)
    end
    helper_method :staff_contacts

    def load_cases
      @cases = Health::Tracing::Case.ongoing.order(last_name: :asc, first_name: :asc)
    end

    def load_case
      @case = Health::Tracing::Case.find(params[:id].to_i)
      @cases = Health::Tracing::Case.where(id: @case.id)
    end

    def load_by_case
      @contacts = Health::Tracing::Contact.where(case_id: @cases.select(:id))
      @managers = Health::Tracing::SiteLeader.where(case_id: @cases.select(:id))
      @staff = Health::Tracing::Staff.where(case_id: @cases.select(:id))

      @by_case = {
        contacts: @contacts.group_by(&:case_id),
        managers: @managers.group_by(&:case_id),
        staff: @staff.group_by(&:case_id),
      }
    end
  end
end
