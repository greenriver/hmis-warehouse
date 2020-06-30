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
          symptoms: ((index_case.symptoms || []) + [index_case.other_symptoms]).reject(&:blank?)&.join('/'),
          testing_date: index_case.testing_date&.strftime('%m/%d/%Y'),
          isolation_start_date: index_case.isolation_start_date&.strftime('%m/%d/%Y'),
          first_name: index_case.first_name,
          last_name: index_case.last_name,
          alias: index_case.aliases,
          dob: index_case.dob&.strftime('%m/%d/%Y'),
          gender: ::HUD.gender(index_case.gender),
          race: index_case.race&.reject(&:blank?)&.map { |r| ::HUD.race(r) }&.join(', '),
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

    def patient_contact_columns
      @patient_contact_columns ||= {
        investigator: {
          section_header: 'INVESTIGATION INFO',
          column_header: 'Investigator',
        },
        contact_interviewed: {
          section_header: '',
          column_header: 'Date contact interviewed',
        },
        alert_in_epic: {
          section_header: '',
          column_header: 'Alert in Epic?',
        },
        index_case_id: {
          section_header: '',
          column_header: 'Linked Index Case ID',
        },
        first_name: {
          section_header: 'CONTACT INFORMATION',
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
        phone_number: {
          section_header: '',
          column_header: 'Phone #',
        },
        address: {
          section_header: '',
          column_header: 'Address if known',
        },
        contact_notified: {
          section_header: '',
          column_header: 'Contact Notified',
        },
        dob_or_age: {
          section_header: '',
          column_header: 'DOB or Estimated Age',
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
        relationship: {
          section_header: '',
          column_header: 'Relationship to index case',
        },
        exposure_location: {
          section_header: '',
          column_header: 'Location of Exposure',
        },
        exposure_nature: {
          section_header: '',
          column_header: 'Nature of Exposure (frequency, duration, timing)',
        },
        location: {
          section_header: '',
          column_header: 'Location where contact may be found',
        },
        sleeping_location: {
          section_header: '',
          column_header: 'Where person sleeps',
        },
        symptomatic: {
          section_header: '',
          column_header: 'Symptomatic?',
        },
        symptoms: {
          section_header: '',
          column_header: 'Symptoms',
        },
        onset_date: {
          section_header: '',
          column_header: 'Symptom Onset date',
        },
        referred_for_testing: {
          section_header: '',
          column_header: 'Referred for testing?',
        },
        test_result_1: {
          section_header: '',
          column_header: 'Test result 1',
        },
        isolation_1: {
          section_header: '',
          column_header: 'Went to Isolation?',
        },
        isolation_location_1: {
          section_header: '',
          column_header: 'Isolation Location',
        },
        quarantine_1: {
          section_header: '',
          column_header: 'Went to Quarantine?',
        },
        quarantine_location_1: {
          section_header: '',
          column_header: 'Quarantine Location',
        },
        test_result_2: {
          section_header: '',
          column_header: 'Test result 2',
        },
        isolation_2: {
          section_header: '',
          column_header: 'Went to Isolation?',
        },
        isolation_location_2: {
          section_header: '',
          column_header: 'Isolation Location',
        },
        quarantine_2: {
          section_header: '',
          column_header: 'Went to Quarantine?',
        },
        quarantine_location_2: {
          section_header: '',
          column_header: 'Quarantine Location',
        },
        test_result_3: {
          section_header: '',
          column_header: 'Test result 3',
        },
        isolation_3: {
          section_header: '',
          column_header: 'Went to Isolation?',
        },
        isolation_location_3: {
          section_header: '',
          column_header: 'Isolation Location',
        },
        quarantine_3: {
          section_header: '',
          column_header: 'Went to Quarantine?',
        },
        quarantine_location_3: {
          section_header: '',
          column_header: 'Quarantine Location',
        },
        test_result_4: {
          section_header: '',
          column_header: 'Test result 4',
        },
        isolation_4: {
          section_header: '',
          column_header: 'Went to Isolation?',
        },
        isolation_location_4: {
          section_header: '',
          column_header: 'Isolation Location',
        },
        quarantine_4: {
          section_header: '',
          column_header: 'Went to Quarantine?',
        },
        quarantine_location_4: {
          section_header: '',
          column_header: 'Quarantine Location',
        },
        notes: {
          section_header: '',
          column_header: 'Notes about this contact:',
        },
      }
    end
    helper_method :patient_contact_columns

    def patient_contacts
      @patient_contacts ||= @contacts.map do |contact|
        {
          investigator: contact.investigator,
          date_interviewed: contact.date_interviewed&.strftime('%m/%d/%Y'),
          alert_in_epic: contact.alert_in_epic,
          index_case_id: contact.case_id.to_s,
          first_name: contact.first_name,
          last_name: contact.last_name,
          alias: contact.aliases,
          phone_number: contact.phone_number,
          address: contact.address,
          contact_notified: contact.notified,
          dob_or_age: [contact.dob&.strftime('%m/%d/%Y'), contact.estimated_age].reject(&:blank?)&.join(' / '),
          gender: ::HUD.gender(contact.gender),
          race: contact.race&.reject(&:blank?)&.map { |r| ::HUD.race(r) }&.join(', '),
          ethnicity: ::HUD.ethnicity(contact.ethnicity),
          preferred_language: contact.preferred_language,
          relationship: contact.relationship_to_index_case,
          exposure_location: contact.location_of_exposure,
          exposure_nature: contact.nature_of_exposure,
          location: contact.location_of_contact,
          sleeping_location: contact.sleeping_location,
          symptomatic: contact.symptomatic,
          symptoms: ((contact.symptoms || []) + [contact.other_symptoms]).reject(&:blank?).join('/'),
          symptom_onset_date: contact.symptom_onset_date&.strftime('%m/%d/%Y'),
          referred_for_testing: contact.referred_for_testing,
          test_result_1: contact.results[0]&.test_result,
          isolation_1: contact.results[0]&.isolated,
          isolation_location_1: contact.results[0]&.isolation_location,
          quarantine_1: contact.results[0]&.quarantine,
          quarantine_location_1: contact.results[0]&.quarantine_location,
          test_result_2: contact.results[1]&.test_result,
          isolation_2: contact.results[1]&.isolated,
          isolation_location_2: contact.results[1]&.isolation_location,
          quarantine_2: contact.results[1]&.quarantine,
          quarantine_location_2: contact.results[1]&.quarantine_location,
          test_result_3: contact.results[2]&.test_result,
          isolation_3: contact.results[2]&.isolated,
          isolation_location_3: contact.results[2]&.isolation_location,
          quarantine_3: contact.results[2]&.quarantine,
          quarantine_location_3: contact.results[2]&.quarantine_location,
          test_result_4: contact.results[3]&.test_result,
          isolation_4: contact.results[3]&.isolated,
          isolation_location_4: contact.results[3]&.isolation_location,
          quarantine_4: contact.results[3]&.quarantine,
          quarantine_location_4: contact.results[3]&.quarantine_location,
          notes: contact.notes,
        }
      end
    end
    helper_method :patient_contacts

    def site_manager_columns
      @site_manager_columns ||= {
        investigator: {
          section_header: 'INVESTIGATION INFO',
          column_header: 'Investigator',
        },
        index_case_id: {
          section_header: '',
          column_header: 'Linked Index Case ID',
        },
        site: {
          section_header: 'SITE LEADERS NOTIFIED (e.g., shelter or clinic managers)',
          column_header: 'Site',
        },
        site_leader: {
          section_header: '',
          column_header: 'Site Leader Name',
        },
        notification_date: {
          section_header: '',
          column_header: 'Notified Date',
        },
      }
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
      @staff_contacts_columns ||= {
        investigator: {
          section_header: 'INVESTIGATION INFO',
          column_header: 'Investigator',
        },
        date_interviewed: {
          section_header: '',
          column_header: 'Date interviewed',
        },
        index_case_id: {
          section_header: '',
          column_header: 'Linked Index Case ID',
        },
        first_name: {
          section_header: 'STAFF CONTACT INFORMATION',
          column_header: 'First Name',
        },
        last_name: {
          section_header: '',
          column_header: 'Last Name',
        },
        dob_or_age: {
          section_header: '',
          column_header: 'DOB or Estimated Age',
        },
        gender: {
          section_header: '',
          column_header: 'Gender',
        },
        address: {
          section_header: '',
          column_header: 'Address if Known',
        },
        phone_number: {
          section_header: '',
          column_header: 'Phone Number',
        },
        site: {
          section_header: '',
          column_header: 'Site',
        },
        contact_notifies: {
          section_header: '',
          column_header: 'Contact Notified',
        },
        exposure_nature: {
          section_header: '',
          column_header: 'Nature of Exposure (frequency, duration, timing)',
        },
        symptomatic: {
          section_header: '',
          column_header: 'Symptomatic?',
        },
        symptoms: {
          section_header: '',
          column_header: 'Symptoms',
        },
        referred_for_testing: {
          section_header: '',
          column_header: 'Referred for testing?',
        },
        test_result: {
          section_header: '',
          column_header: 'Test result',
        },
        notes: {
          section_header: '',
          column_header: 'Notes about this contact:',
        },
      }
    end
    helper_method :staff_contacts_columns

    def staff_contacts
      @staff_contacts ||= @staff.map do |contact|
        {
          investigator: contact.investigator,
          date_interviewed: contact.date_interviewed,
          index_case_id: contact.case_id.to_s,
          first_name: contact.first_name,
          last_name: contact.last_name,
          dob_or_age: [contact.dob&.strftime('%m/%d/%Y'), contact.estimated_age].reject(&:blank?)&.join(' / '),
          gender: ::HUD.gender(contact.gender),
          address: contact.address,
          phone_number: contact.phone_number,
          site: contact.site_name,
          contact_notified: contact.notified,
          exposure_nature: contact.nature_of_exposure,
          symptomatic: contact.symptomatic,
          symptoms: ((contact.symptoms || []) + [contact.other_symptoms]).reject(&:blank?).join('/'),
          referred_for_testing: contact.referred_for_testing,
          test_result: contact.test_result,
          notes: contact.notes,
        }
      end
    end
    helper_method :staff_contacts

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
