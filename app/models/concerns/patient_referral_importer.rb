###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PatientReferralImporter
  extend ActiveSupport::Concern
  included do
    def self.column_headers
      {
        medicaid_id: 'Medicaid_ID',
        last_name: 'Member_Name_Last',
        first_name: 'Member_Name_First',
        middle_initial: 'Member_Middle_Initial',
        suffix: 'Member_Suffix',
        birthdate: 'Member_Date_of_Birth',
        gender: 'Member_Sex',
        aco_name: 'ACO_MCO_Name',
        aco_mco_pid: 'ACO_MCO_PID',
        aco_mco_sl: 'ACO_MCO_SL',
        health_plan_id: 'Health_Plan_ID',
        cp_assignment_plan: 'Member_CP_Assignment_Plan',
        cp_name_dsrip: 'CP_Name_DSRIP',
        cp_name_official: 'CP_Name_Official',
        cp_pid: 'CP_PID',
        cp_sl: 'CP_SL',
        enrollment_start_date: 'Enrollment_Start_Date',
        start_reason_description: 'Start_Reason_Desc',
        address_line_1: 'Residential_Address_Line_1',
        address_line_2: 'Residential_Address_Line_2',
        address_city: 'Residential_Address_City',
        address_state: 'Residential_Address_State',
        address_zip: 'Residential_Address_ZipCode_1',
        address_zip_plus_4: 'Residential_Address_ZipCode_2',
        email: 'Email',
        phone_cell: 'Phone_Number_Cell',
        phone_day: 'Phone_Number_Day',
        phone_night: 'Phone_Number_Night',
        primary_language: 'Primary_Language_Spoken_Desc',
        primary_diagnosis: 'Primary_Diagnosis',
        secondary_diagnosis: 'Secondary_Diagnosis',
        pcp_last_name: 'PCP_Name_Last',
        pcp_first_name: 'PCP_Name_First',
        pcp_npi: 'PCP_NPI',
        pcp_address_line_1: 'PCP_Address_Line_1',
        pcp_address_line_2: 'PCP_Address_Line_2',
        pcp_address_city: 'PCP_Address_City',
        pcp_address_state: 'PCP_Address_State',
        pcp_address_zip: 'PCP_Address_ZipCode',
        pcp_address_phone: 'PCP_Phone_Number',
        dmh: 'DMH_Flag',
        dds: 'DDS_Flag',
        eoea: 'EOEA_Flag',
        ed_visits: 'ED_Visits',
        snf_discharge: 'SNF_Discharge',
        identification: 'Identification_Flag',
        record_status: 'Record_Status',
        record_updated_on: 'Record_Update_Date',
        exported_on: 'Export_Date',
      }
    end
  end
end
