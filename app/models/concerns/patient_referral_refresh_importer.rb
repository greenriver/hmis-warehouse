###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PatientReferralRefreshImporter
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
        cp_assignment_plan: 'Member_CP_Assignment_Plan',
        cp_name_official: 'CP_Name_Official',
        cp_pid: 'CP_PID',
        cp_sl: 'CP_SL',
        enrollment_start_date: 'Enrollment_Start_Date',
        start_reason_description: 'Start_Reason_Desc',
        disenrollment_date: 'Disenrollment_Date',
        stop_reason_description: 'Stop_Reason_Desc',
        record_status: 'Record_Status',
        record_updated_on: 'Record_Update_Date',
        exported_on: 'Export_Date',
      }
    end
  end
end
