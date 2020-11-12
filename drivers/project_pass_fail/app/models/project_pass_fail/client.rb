###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ProjectPassFail
  class Client < GrdaWarehouseBase
    self.table_name = :project_pass_fails_clients
    belongs_to :project_pass_fail, inverse_of: :clients
    belongs_to :project, inverse_of: :clients

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
        gender: apr_client.gender,
        name_quality: apr_client.name_quality,
        race: apr_client.race,
        ssn_quality: apr_client.ssn_quality,
        ssn: apr_client.ssn,
        veteran_status: apr_client.veteran_status,
        relationship_to_hoh: apr_client.relationship_to_hoh,
        enrollment_created: apr_client.enrollment_created,
        enrollment_coc: apr_client.enrollment_coc,
      )
    end

    def calculate_time_to_enter
      assign_attributes(
        days_to_enter_entry_date: (enrollment_created - first_date_in_program).to_i,
      )
    end
  end
end
