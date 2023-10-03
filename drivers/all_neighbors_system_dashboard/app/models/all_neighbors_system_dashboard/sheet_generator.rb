###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  module SheetGenerator
    extend ActiveSupport::Concern

    included do
      def sheets
        {
          'HMIS Enrollments' => [
            {
              intervention: 'Intervention',
              household_id: 'Case ID',
              household_type: 'Household Type',
              prior_living_situation_category: 'HH Prior Living Situation',
              enrollment_id: 'Enroll ID',
              entry_date: 'Enroll Date',
              move_in_date: 'Move In Date',
              exit_date: 'Exit Date',
              adjusted_exit_date: 'Adjusted Exit Date',
              exit_type: 'APR_ExitType',
              destination: 'ExitDestination_Int',
              destination_text: 'ExitDestination_Val',
              relationship: 'Relationship',
              personal_id: 'Client ID',
              age: 'Age',
              gender: 'Gender',
              primary_race: 'Race',
              race_list: 'RaceDescList',
              ethnicity: 'Ethnicity',
              ce_entry_date: 'CAS Enroll Date',
              ce_referral_date: 'CAS Referral Date',
              ce_referral_id: 'CAS Referral ID',
              return_date: 'Return Date',
              report_start: 'Report Start',
              report_end: 'Report End',
              enrollment_count: 'Enrollments',
              move_in_count: 'Move Ins',
              scaffold_link: 'ScaffoldLink',
              project_id: 'Program ID',
              project_name: 'Program Name',
              project_type: 'Program Type INT',
            },
            enrollment_data,
          ],
          'CE Events' => [
            {
              personal_id: 'ClientID',
              event_id: 'ServiceID',
              event_date: 'EventDate',
              event: 'Event',
              location: 'LocationCrisisORPHHousing',
              project_name: 'ProgramName',
              project_type: 'ProgramType',
              referral_result: 'ReferralResult',
              result_date: 'ResultDate',
              report_start: 'ReportStartDate',
              report_end: 'ReportEndDate',
              run_date: 'RunDate',
              source_enrollment_id: 'EnrollID',
            },
            ce_event_data,
          ],
          # 'Enrollments DV' => [
          #   {
          #     project_name: 'Program Name',
          #     label: 'Label',
          #     intervention: 'Intervention',
          #     household_id: 'Case ID',
          #     household_type: 'Household Type',
          #     prior_living_situation_category: 'HH Prior Living Situation',
          #     enrollment_id: 'Enroll ID',
          #     entry_date: 'Enroll Date',
          #     move_in_date: 'Move In Date',
          #     exit_date: 'Exit Date',
          #     relationship: 'Relationship',
          #     client_id: 'Client ID',
          #     age: 'Age',
          #     gender: 'Gender',
          #     primary_race: 'Race',
          #     ethnicity: 'Ethnicity',
          #     ce_entry_date: 'CAS Enroll Date',
          #     ce_referral_date: 'CAS Referral Date',
          #     return_date: 'Return Date',
          #     report_start: 'Report Start',
          #     report_end: 'Report End',
          #     enrollment_count: 'Enrollments',
          #     move_in_count: 'Move Ins',
          #   },
          #   [],
          # ],
          'Ratios - Project Level' => [
            {
              project_type: 'Program Type',
              project_id: 'Program ID',
              project_name: 'Program Name',
              primary_race: 'RaceDesc',
              ethnicity: 'Ethnicity',
              clients_by_demographic: 'Clients by DemCat',
              clients_by_segment: 'Clients by Segment',
              households_by_demographic: 'HoHs by DemCat',
              households_by_segment: 'HoHs by Segment',
              project_category: 'Project Category',
              report_start: 'ReportStart',
              report_end: 'ReportEnd',
            },
            project_ratios,
          ],
          'Ratios - System Level' => [
            {
              project_type: 'Program Type',
              project_category: 'Project Category',
              primary_race: 'RaceDesc',
              ethnicity: 'Ethnicity',
              clients_by_demographic: 'Clients by DemCat',
              clients_by_segment: 'Clients by Segment',
              households_by_demographic: 'HoHs by DemCat',
              households_by_segment: 'HoHs by Segment',
              report_start: 'ReportStart',
              report_end: 'ReportEnd',
            },
            system_ratios,
          ],
        }
      end

      def ce_event_data
        universe.members&.first&.universe_membership&.events
      end

      def attach_rendered_xlsx
        result_file.attach(filename: "All Neighbors System Dashboard #{id}.xlsx", io: StringIO.new(render_xlsx))
      end

      def render_xlsx
        ApplicationController.render(
          template: 'all_neighbors_system_dashboard/warehouse_reports/reports/sheet',
          formats: [:xlsx],
          assigns: {
            sheets: sheets,
          },
        )
      end
    end
  end
end
