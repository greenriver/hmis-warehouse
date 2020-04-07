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
    end

    def download
      if params[:tab] == 'completed'
        @cases = @completed
      else
        @cases = @ongoing
      end
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
      columns.keys.each { |name| info[name] = [] }
      # Index Case info
      info[:name] << index_case.name
      info[:dob] << index_case.dob&.strftime('%m/%d/%y')
      info[:testing_date] << index_case.testing_date&.strftime('%m/%d/%y')
      info[:infectious_date] << index_case.infectious_start_date&.strftime('%m/%d/%y')
      # By site
      sites = (@by_case[:contacts][index_case.id].map(&:sleeping_location) +
        @by_case[:staff][index_case.id].map(&:site_name)).uniq.sort
      sites.each do |site_name|
        # Site label
        info[:site_name] << site_name
        # Staff
        staff_for_site = @by_case[:staff][index_case.id].select { |staff| staff.site_name == site_name }
        staff_for_site.each do |staff|
          info[:staff] << staff.name
          info[:staff_notified] << staff.notified
        end
        # Contacts
        contacts_for_site = @by_case[:contacts][index_case.id].select { |contact| contact.sleeping_location == site_name }
        contacts_for_site.each do |contact|
          info[:contact] << [contact.name, contact.dob&.strftime('%m/%d/%y')].compact.join(' ')
          info[:contact_notified] << contact.notified
          info[:contact_disposition] << disposition(contact)
          info[:notes] << contact.notes
        end
        # Fill columns
        rows = columns.keys.map { |column| info[column].size }.max
        columns.keys.each do |column|
          info[column] = info[column] + Array.new(rows - info[column].size)
        end
      end
      info
    end
    helper_method :case_info_sheet

    def disposition(contact)
      contact.isolation_location || contact.quarantine_location
    end

    def load
      @ongoing = Health::Tracing::Case.ongoing
      @completed = Health::Tracing::Case.completed
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
