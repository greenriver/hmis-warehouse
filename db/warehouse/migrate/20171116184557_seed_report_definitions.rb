class SeedReportDefinitions < ActiveRecord::Migration

  REPORTS = {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/chronic',
        name: 'Potentially Chronic Clients',
        description: 'Disabled clients who are currently homeless and have been in a project at least 12 of the last 36 months.'
      },
      {
        url: 'warehouse_reports/client_in_project_during_date_range',
        name: 'Clients in a project for a given date range',
        description: 'Who was enrolled at a specific project during a given time.'
      },
      {
        url: 'warehouse_reports/veteran_details/exits',
        name: 'Veteran Exits',
        description: 'Details of veterans who exited from homelessness during a given date range.'
      },
      {
        url: 'warehouse_reports/hud_chronics',
        name: 'HUD Chronic',
        description: 'See who is considered chronically homeless according to HUD.'
      },
      {
        url: 'warehouse_reports/first_time_homeless',
        name: 'First Time Homeless',
        description: 'Clients who first used residential services within a given date range.'
      },
      {
        url: 'warehouse_reports/active_veterans',
        name: 'Active Veterans for a given date range',
        description: 'Find veterans who were homeless during a date range, limitable by project type.'
      },
      {
        url: 'warehouse_reports/disabilities',
        name: 'Enrolled clients with selected disabilities',
        description: 'Find currently enrolled clients based on disabilities'
      },
      {
        url: 'warehouse_reports/open_enrollments_no_service',
        name: 'Open Bed-Night Enrollments with No Recent Service',
        description: 'This report is a bit slow to load'
      },
      {
        url: 'warehouse_reports/find_by_id',
        name: 'Bulk Find Client Details by ID',
        description: 'Lookup clients by warehouse ID. Useful for doing research outside of the warehouse and then reconnecting clients.'
      },
      {
        url: 'warehouse_reports/chronic_housed',
        name: 'Clients Housed, Previously on the Chronic List',
        description: 'See who was housed in permanent housing after being on the chronic list.'
      },
    ],
    'Data Quality' => [
      {
        url: 'warehouse_reports/missing_projects',
        name: 'Missing Projects ',
        description: "Shows Project IDs for enrollment records where the project isn't in the source data."
      },
      {
        url: 'warehouse_reports/future_enrollments',
        name: 'Clients with future enrollments',
        description: 'List any clients who have enrollments in the future.'
      },
      {
        url: 'warehouse_reports/entry_exit_service',
        name: 'Clients with Single Day Enrollments with Services',
        description: 'Clients who received services for one-day enrollments in housing related projects.'
      },
      {
        url: 'warehouse_reports/missing_values',
        name: 'Missing values in HUD tables',
        description: 'Find the frequency of missing values in HUD Client and Enrollment tables.'
      },
      {
        url: 'warehouse_reports/dob_entry_same',
        name: 'DOB = Entry date',
        description: "List clients who's first entry date is on their birthdate."
      },
      {
        url: 'warehouse_reports/long_standing_clients',
        name: 'Long Standing Clients',
        description: 'List clients who have been enrolled in an emergency shelter for a given number of years.'
      },
      {
        url: 'warehouse_reports/bed_utilization',
        name: 'Bed Utilization',
        description: 'Bed utilization within the programs of an organization.'
      },
      {
        url: 'warehouse_reports/project/data_quality',
        name: 'Project Data Quality',
        description: 'A comprehensive view into the details of how well projects meet various data quality goals.'
      },
      {
        url: 'warehouse_reports/non_alpha_names',
        name: 'Client with odd characters in their names',
        description: "List clients who's first or last name starts with a non-alphabetic character."
      },
      {
        url: 'warehouse_reports/really_old_enrollments',
        name: 'Really Old Enrollments',
        description: 'List clients who have enrollments prior to 1970.'
      },
      {
        url: 'warehouse_reports/length_of_stay',
        name: 'Currently enrolled clients with length of stay',
        description: 'The length of stay per program of currently enrolled clients aggregated by time interval.'
      },
      {
        url: 'warehouse_reports/project_type_reconciliation',
        name: 'Project Type Reconciliation',
        description: 'See all projects that behave as a project type other than that in the sending system.'
      },
    ],
    'CAS' => [
      {
        url: 'warehouse_reports/manage_cas_flags',
        name: 'Manage CAS Flags',
        description: 'Use this report to bulk update <b>available in cas, disability verification on file, and HAN release on file</b>'
      },
      {
        url: 'warehouse_reports/cas/chronic_reconciliation',
        name: 'Chronic Reconcilliation',
        description: "See who is available in CAS but not on the chronic list, and who's not available in CAS, but is on the chronic list."
      },
      {
        url: 'warehouse_reports/cas/decision_efficiency',
        name: 'Decision Efficiency',
        description: 'Shows how quickly clients move through CAS steps.'
      },
      {
        url: 'warehouse_reports/cas/canceled_matches',
        name: 'Canceled Matches',
        description: 'See when matches were canceled and who was involved.'
      },
      {
        url: 'warehouse_reports/cas/decline_reason',
        name: 'Decline Reason',
        description: 'Why CAS matches were declined.'
      },
    ]
  }

  def clean value
    GrdaWarehouse::WarehouseReports::ReportDefinition.sanitize(value)
  end

  def up
    REPORTS.each do |group, reports|
      reports.each do |report|
        execute (
          "insert into report_definitions (report_group, url, name, description) VALUES 
           (#{clean(group)}, #{clean(report[:url])}, #{clean(report[:name])}, #{clean(report[:description])})"
        )
      end
    end
  end

  def down
    execute 'delete from report_definitions'
  end

end
