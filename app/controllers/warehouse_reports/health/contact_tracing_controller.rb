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

    def index_case_columns
      @index_case_columns ||= {
        index_case_id: {
          section_header: '',
          column_header: 'Index Case ID',
        },
        investigator: {
          section_header: 'INVESTIGATION INFORMATION',
          column_header: 'Investigator',
        },
        date_listed: {
          section_header: '',
          column_header: 'Date listed',
        },
        date_interviewed: {
          section_header: '',
          column_header: 'Date interviewed',
        },
        alert_in_epic: {
          section_header: '',
          column_header: 'Alert in Epic?',
        },
        investigation_complete: {
          section_header: '',
          column_header: 'Investigation complete?',
        },
        infectious_start_date: {
          section_header: 'PERIOD OF INTEREST',
          column_header: 'Infectious Start Date',
        },
        plus_two_weeks: {
          section_header: '',
          column_header: 'Inf Start Date + 14d',
        },
        symptoms: {
          section_header: '',
          column_header: 'Symptoms',
        },
        testing_date: {
          section_header: '',
          column_header: 'Testing Date',
        },
        isolation_start_date: {
          section_header: '',
          column_header: 'Isolation Start Date',
        },
        first_name: {
          section_header: 'INDEX CASE INFORMATION',
          column_header: 'First Name',
        },
        last_name: {
          section_header: '',
          column_header: 'Last Name',
        },
        alias: {
          section_header: '',
          column_header: 'Alias',
        },
        dob: {
          section_header: '',
          column_header: 'DOB',
        },
        gender: {
          section_header: '',
          column_header: 'Gender',
        },
        race: {
          section_header: '',
          column_header: 'Race',
        },
        ethnicity: {
          section_header: '',
          column_header: 'Ethnicity',
        },
        preferred_language: {
          section_header: '',
          column_header: 'Preferred Language',
        },
        where_person_sleeps: {
          section_header: '',
          column_header: 'Where Person Sleeps',
        },
        other_location_1: {
          section_header: '',
          column_header: 'Other Location 1',
        },
        other_location_2: {
          section_header: '',
          column_header: 'Other Location 2',
        },
        other_location_3: {
          section_header: '',
          column_header: 'Other Location 3',
        },
        other_location_4: {
          section_header: '',
          column_header: 'Other Location 4',
        },
        occupation: {
          section_header: '',
          column_header: 'Occupation (if applicable)/Where do they work',
        },
        recent_incarceration: {
          section_header: '',
          column_header: 'Recent incarceration',
        },
        additional_locations: {
          section_header: '',
          column_header: '[add more location columns here as needed]',
        },
        notes: {
          section_header: '',
          column_header: 'Notes about this case:',
        },
      }
    end
    helper_method :index_case_columns

    def index_cases
      @index_cases ||= @cases.map do |index_case|
        {
          index_case_id: index_case.id.to_s,
          investigator: index_case.investigator,
          date_listed: index_case.date_listed&.strftime('%m/%d/%Y'),
          date_interviewed: index_case.date_interviewed&.strftime('%m/%d/%Y'),
          alert_in_epic: index_case.alert_in_epic,
          investigation_complete: index_case.complete,
          infectious_start_date: index_case.infectious_start_date&.strftime('%m/%d/%Y'),
          plus_two_weeks: index_case.day_two&.strftime('%m/%d/%Y'),
          symptoms: (index_case.symptoms + [index_case.other_symptoms]).reject(&:blank?).join('/'),
          testing_date: index_case.testing_date&.strftime('%m/%d/%Y'),
          isolation_start_date: index_case.isolation_start_date&.strftime('%m/%d/%Y'),
          first_name: index_case.first_name,
          last_name: index_case.last_name,
          alias: index_case.aliases,
          dob: index_case.dob&.strftime('%m/%d/%Y'),
          gender: ::HUD.gender(index_case.gender),
          race: index_case.race.reject(&:blank?).map { |r| ::HUD.race(r) }.join(', '),
          ethnicity: ::HUD.ethnicity(index_case.ethnicity),
          preferred_language: index_case.preferred_language,
          where_person_sleeps: index_case.locations[0],
          other_location_1: index_case.locations[1],
          other_location_2: index_case.locations[2],
          other_location_3: index_case.locations[3],
          other_location_4: index_case.locations[4],
          occupation: index_case.occupation,
          recent_incarceration: index_case.recent_incarceration,
          additional_locations: index_case.locations[5..]&.join(', '),
          notes: index_case.notes,
        }
      end
    end
    helper_method :index_cases

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
