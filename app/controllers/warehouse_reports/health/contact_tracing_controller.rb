###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class ContactTracingController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_edit_health_emergency_contact_tracing!
    before_action :load_cases
    before_action :load_by_case

    def index
      @paginated = @cases.page(params[:page]).per(25)
    end

    def download
      render xlsx: 'download', filename: "Contact Tracing #{Date.current}.xlsx"
    end

    def columns
      @columns ||= {
        name: 'Confirmed Case Name',
        dob: Health::Tracing::Case.label_for(:dob),
        testing_date: Health::Tracing::Case.label_for(:testing_date),
        infectious_date: Health::Tracing::Case.label_for(:infectious_start_date),
        site_name: 'Site(s) Affected',
        staff: 'Staff Close Contacts',
        staff_notified: 'Staff Notified',
        contact: 'Close Contacts',
        contact_notified: 'Contact Notified',
        contact_disposition: 'Disposition',
        notes: 'Notes',
      }
    end
    helper_method :columns

    def case_info_sheet(index_case)
      info = {}
      columns.each_key { |name| info[name] = [] }
      # Index Case info
      info[:name] << index_case.name
      info[:dob] << index_case.dob&.strftime('%m/%d/%Y')
      info[:testing_date] << index_case.testing_date&.strftime('%m/%d/%Y')
      info[:infectious_date] << index_case.infectious_start_date&.strftime('%m/%d/%Y')

      contacts_for_case = @by_case[:contacts][index_case.id] || []
      staff_for_case =  @by_case[:staff][index_case.id] || []

      # By site
      sites = (contacts_for_case.map(&:sleeping_location) +
        staff_for_case.map(&:site_name)).uniq.sort
      sites.each do |site_name|
        # Site label
        info[:site_name] << site_name
        # Staff
        staff_for_site = staff_for_case.select { |staff| staff.site_name == site_name }
        staff_for_site.each do |staff|
          info[:staff] << staff.name
          info[:staff_notified] << staff.notified
        end
        # Contacts
        contacts_for_site = contacts_for_case.select { |contact| contact.sleeping_location == site_name }
        contacts_for_site.each do |contact|
          info[:contact] << [contact.name, contact.dob&.strftime('%m/%d/%Y')].compact.join(' ')
          info[:contact_notified] << contact.notified
          info[:contact_disposition] << disposition(contact)
          info[:notes] << contact.notes
        end
        # Fill columns
        rows = columns.keys.map { |column| info[column].size }.max
        columns.each_key do |column|
          info[column] = info[column] + Array.new(rows - info[column].size)
        end
      end
      info
    end
    helper_method :case_info_sheet

    def disposition(contact)
      contact.isolation_location || contact.quarantine_location
    end

    def load_cases
      @cases = Health::Tracing::Case.ongoing.order(last_name: :asc, first_name: :asc)
    end

    def load_by_case
      @contacts = Health::Tracing::Contact.all
      @managers = Health::Tracing::SiteLeader.all
      @staff = Health::Tracing::Staff.all

      @by_case = {
        contacts: @contacts.group_by(&:case_id),
        managers: @managers.group_by(&:case_id),
        staff: @staff.group_by(&:case_id),
      }
    end
  end
end
