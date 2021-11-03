###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectPassFail
  class Client < GrdaWarehouseBase
    self.table_name = :project_pass_fails_clients
    belongs_to :project_pass_fail, inverse_of: :clients
    belongs_to :project, inverse_of: :clients, optional: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true

    def calculate_universal_data_elements(apr_client)
      assign_attributes(
        client_id: apr_client.client_id,
        first_name: apr_client.first_name,
        last_name: apr_client.last_name,
        first_date_in_program: apr_client.first_date_in_program,
        last_date_in_program: apr_client.last_date_in_program,
        disabling_condition: apr_client.disabling_condition,
        dob: apr_client.dob,
        dob_quality: apr_client.dob_quality,
        ethnicity: apr_client.ethnicity,
        gender_multi: apr_client.gender_multi,
        name_quality: apr_client.name_quality,
        race: apr_client.race,
        ssn_quality: apr_client.ssn_quality,
        ssn: apr_client.ssn,
        veteran_status: apr_client.veteran_status,
        relationship_to_hoh: apr_client.relationship_to_hoh,
        enrollment_created: apr_client.enrollment_created,
        enrollment_coc: apr_client.enrollment_coc,
        income_at_entry: apr_client.income_from_any_source_at_start,
      )
    end

    def calculate_time_to_enter
      assign_attributes(
        days_to_enter_entry_date: (enrollment_created - first_date_in_program).to_i,
      )
    end

    def self.detail_headers
      {
        first_name: 'First Name',
        last_name: 'Last Name',
        name_quality: 'Name Quality',
        first_date_in_program: 'Entry Date',
        last_date_in_program: 'Exit Date',
        disabling_condition: 'Disabling Condition',
        dob: 'DOB',
        dob_quality: 'DOB Quality',
        ssn: 'SSN',
        ssn_quality: 'SSN Quality',
        ethnicity: 'Ethnicity',
        gender: 'Gender',
        gender_multi: 'Gender 2022',
        race: 'Race',
        veteran_status: 'Veteran Status',
        relationship_to_hoh: 'Relationship to HoH',
        enrollment_coc: 'Enrollment CoC',
        enrollment_created: 'Enrollment Added On',
        days_to_enter_entry_date: 'Days Between Entry and Date Added',
        days_served: 'Days Served',
        income_at_entry: 'Income at Entry',
      }
    end
  end
end
