require 'faker'

def setup_fake_user
  unless User.find_by(email: 'noreply@example.com').present?
    # Add roles
    admin = Role.where(name: 'Admin').first_or_create
    dnd_staff = Role.where(name: 'CoC Staff').first_or_create

    # Add a user.  This should not be added in production
    unless Rails.env =~ /production|staging/
      inital_password = Faker::Internet.password(min_length: 16)
      user = User.new
      user.email = 'noreply@example.com'
      user.first_name = "Sample"
      user.last_name = 'Admin'
      user.password = user.password_confirmation = inital_password
      user.confirmed_at = Time.now
      user.roles = [admin, dnd_staff]
      user.save!
      puts "Created initial admin email: #{user.email}  password: #{user.password}"
    end
  end
end

# Reports
def report_list
  {
    'Operational Reports' => [
      {
        url: 'warehouse_reports/chronic',
        name: 'Potentially Chronic Clients',
        description: 'Disabled clients who are currently homeless and have been in a project at least 12 of the last 36 months.<br />Calculated using HMIS data.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/client_in_project_during_date_range',
        name: 'Clients in a project for a given date range',
        description: 'Who was enrolled at a specific project during a given time.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/hud_chronics',
        name: 'HUD Chronic',
        description: 'Clients who meet the HUD definition of Chronically Homeless as outlined in the HMIS Glossary.<br />Calculated using self-report data from entry assessments.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/first_time_homeless',
        name: 'First Time Homeless',
        description: 'Clients who first used residential services within a given date range.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/active_veterans',
        name: 'Active Veterans for a given date range',
        description: 'Find veterans who were homeless during a date range, limitable by project type.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/disabilities',
        name: 'Enrolled clients with selected disabilities',
        description: 'Find currently enrolled clients based on disabilities',
        limitable: true,
      },
      {
        url: 'warehouse_reports/open_enrollments_no_service',
        name: 'Open Bed-Night Enrollments with No Recent Service',
        description: 'Client enrollments that may need to be closed.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/find_by_id',
        name: 'Bulk Find Client Details by ID',
        description: 'Lookup clients by warehouse ID. Useful for doing research outside of the warehouse and then reconnecting clients.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/chronic_housed',
        name: 'Clients Housed, Previously on the Chronic List',
        description: 'See who was housed in permanent housing after being on the chronic list.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/client_details/actives',
        name: 'Active Client Detail',
        description: 'Clients with service within a date range.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/client_details/entries',
        name: 'Client Entry Detail',
        description: 'Clients with entries into a project type within a date range.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/client_details/exits',
        name: 'Client Exit Detail',
        description: 'Clients with entries into a project type within a date range.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/expiring_consent',
        name: 'Expiring Consent',
        description: 'Clients whose consent form has expired or expires soon.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/hmis_exports',
        name: 'HUD HMIS Exports',
        description: 'Export data in the HUD standard format.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/initiatives',
        name: 'Initiatives',
        description: 'Standard reporting for initiatives, RRH, Youth, Vets...',
        limitable: true,
      },
      {
        url: 'warehouse_reports/touch_point_exports',
        name: 'Export Touch Points',
        description: 'Export CSVs of ETO TouchPoints.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/recidivism',
        name: 'Recidivism Report',
        description: 'Clients enrolled in PH who have service in ES or SO after the move-in-date.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/tableau_dashboard_export',
        name: 'Tableau Dashboard Export',
        description: 'Download dashboard data sets.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/hashed_only_hmis_exports',
        name: 'HUD HMIS CSV Exports (Hashed Only)',
        description: 'Export data in the HUD HMIS exchange format with PII hashed',
        limitable: true,
      },
      {
        url: 'warehouse_reports/rrh',
        name: 'Rapid Rehousing Dashboard',
        description: '',
        limitable: true,
      },
      {
        url: 'warehouse_reports/youth_export',
        name: 'Youth Export',
        description: 'Youth data for a given time frame.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/cohort_changes',
        name: 'Cohort Changes Report',
        description: 'Explore and download data related to changes in cohorts over time',
        limitable: false,
      },
      {
        url: 'warehouse_reports/incomes',
        name: 'Client Incomes',
        description: 'Report client incomes and sources',
        limitable: false,
      },
      {
        url: 'warehouse_reports/psh',
        name: 'Permanent Supportive Housing Dashboard',
        description: '',
        limitable: true,
      },
      {
        url: 'warehouse_reports/youth_intakes',
        name: 'Homeless Youth Program Report',
        description: '',
        limitable: true,
      },
      {
        url: 'warehouse_reports/client_details/last_permanent_zips',
        name: 'Last Permanent Zip Report',
        description: 'List open enrollments within a date range and the zip codes of last permanent residence.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/enrolled_project_type',
        name: 'Enrollments per project type',
        description: 'A list of clients who were enrolled in a set of project types for a given date range.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/re_entry',
        name: 'Homelessness Re-Entry',
        description: 'Details on clients who returned to homelessness after a 60 day break',
        limitable: true,
      },
      {
        url: 'warehouse_reports/outflow',
        name: 'Client Outflow',
        description: 'Clients who exited homelessness, or who have no recent homeless service.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/youth_follow_ups',
        name: 'Homeless Youth Follow Up Report',
        description: 'Youth who require a three month follow up',
        limitable: true,
      },
      {
        url: 'warehouse_reports/dv_victim_service',
        name: 'DV Victim Service Report',
        description: 'Clients fleeing domestic violence.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/youth_export',
        name: 'Youth Data Export',
        description: 'Youth data for a given time frame.',
        limitable: true,
      },
    ],
    'Data Quality' => [
      {
        url: 'warehouse_reports/missing_projects',
        name: 'Missing Projects ',
        description: "Shows Project IDs for enrollment records where the project isn''t in the source data.",
        limitable: false,
      },
      {
        url: 'warehouse_reports/future_enrollments',
        name: 'Clients with future enrollments',
        description: 'List any clients who have enrollments in the future.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/entry_exit_service',
        name: 'Clients with Single Day Enrollments with Services',
        description: 'Clients who received services for one-day enrollments in housing related projects.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/missing_values',
        name: 'Missing values in HUD tables',
        description: 'Find the frequency of missing values in HUD Client and Enrollment tables.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/dob_entry_same',
        name: 'DOB = Entry date',
        description: "List clients who''s first entry date is on their birthdate.",
        limitable: true,
      },
      {
        url: 'warehouse_reports/long_standing_clients',
        name: 'Long Standing Clients',
        description: 'List clients who have been enrolled in an emergency shelter for a given number of years.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/bed_utilization',
        name: 'Bed Utilization',
        description: 'Bed utilization within the programs of an organization.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/project/data_quality',
        name: 'Project Data Quality',
        description: 'A comprehensive view into the details of how well projects meet various data quality goals.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/non_alpha_names',
        name: 'Client with odd characters in their names',
        description: "List clients who''s first or last name starts with a non-alphabetic character.",
        limitable: false,
      },
      {
        url: 'warehouse_reports/really_old_enrollments',
        name: 'Really Old Enrollments',
        description: 'List clients who have enrollments prior to 1970.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/length_of_stay',
        name: 'Currently enrolled clients with length of stay',
        description: 'The length of stay per program of currently enrolled clients aggregated by time interval.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/project_type_reconciliation',
        name: 'Project Type Reconciliation',
        description: 'See all projects that behave as a project type other than that in the sending system.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/anomalies',
        name: 'Client Anomalies',
        description: 'Reported anomalies and their status.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/double_enrollments',
        name: 'Doubly Enrolled Clients',
        description: 'Clients enrolled in multiple simultaneous projects of the same type.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/conflicting_client_attributes',
        name: 'Clients with Conflicting Reported Attributes',
        description: 'Identify clients whose source record attributes differ between data sources.',
        limitable: true,
      },
    ],
    'CAS' => [
      {
        url: 'warehouse_reports/manage_cas_flags',
        name: 'Manage CAS Flags',
        description: 'Use this report to bulk update <b>available in cas, disability verification on file, and HAN release on file</b>',
        limitable: false,
      },
      {
        url: 'warehouse_reports/cas/chronic_reconciliation',
        name: 'Chronic Reconcilliation',
        description: "See who is available in CAS but not on the chronic list, and who''s not available in CAS, but is on the chronic list.",
        limitable: false,
      },
      {
        url: 'warehouse_reports/cas/decision_efficiency',
        name: 'Decision Efficiency',
        description: 'Shows how quickly clients move through CAS steps.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/cas/canceled_matches',
        name: 'Canceled Matches',
        description: 'See when matches were canceled and who was involved.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/cas/decline_reason',
        name: 'Decline Reason',
        description: 'Why CAS matches were declined.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/consent',
        name: 'Consent Processing',
        description: 'Review and process consent and disability forms for potentially CAS ready clients.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/cas/process',
        name: 'Match Process',
        description: 'Export of time between steps',
        limitable: false,
      },
      {
        url: 'warehouse_reports/cas/apr',
        name: 'CAS APR',
        description: 'High-level counts of CAS activity for a date range',
        limitable: false,
      },
      {
        url: 'warehouse_reports/cas/vacancies',
        name: 'CAS Vacancies',
        description: 'CAS vacancies for a given date range',
        limitable: true,
      },
      {
        url: 'warehouse_reports/cas/rrh_desired',
        name: 'Clients Interested in RRH',
        description: 'Who has indicated interest in RRH but does not yet have any consent on file',
        limitable: false,
      },
      {
        url: 'warehouse_reports/cas/ce_assessments',
        name: 'Coordinated-Entry Assessment Status',
        description: _('Find clients who need a Coordinated Entry re-assessment.'),
        limitable: true,
      },
    ],
    'Audit Reports' => [
      {
        url: 'audit_reports/agency_user',
        name: 'Agency User Audit Report',
        description: 'Report recent warehouse activity by agency users',
        limitable: false,
      },
      {
        url: 'audit_reports/user_login',
        name: 'User Login Report',
        description: 'Report most recent logins by users',
        limitable: false,
      },
    ],
    'Health' => [
      {
        url: 'warehouse_reports/health/overview',
        name: 'Health Dashboard',
        description: 'Overview of patient metrics.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/confidential_touch_point_exports',
        name: 'Health-related TouchPoint Export',
        description: 'Export for any Confidential Health-related TouchPoints.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health/member_status_reports',
        name: 'CP Member Status and Outreach',
        description: 'Download member status reports',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health/claims',
        name: 'Claim Generation',
        description: 'Generate and download claims files. (837P)',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health/agency_performance',
        name: 'Agency Performance',
        description: 'Summary data on agency performance in the BH CP.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health/patient_referrals',
        name: 'Patient Referrals',
        description: 'View and update batches of patient referrals by referral date.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health/premium_payments',
        name: 'Process Premium Payments (820)',
        description: 'Convert 820 files into human-readable Excel files',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health/eligibility',
        name: 'Eligibility Determination',
        description: 'Generate and download eligibility determination files. (270/271)',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health/enrollments',
        name: 'Health Care Enrollments (834)',
        description: 'Update patient enrollments.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health/housing_status',
        name: 'Patient Housing Status',
        description: 'Patient housing status report for ACOs.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health/cp_roster',
        name: 'CP Rosters',
        description: 'Upload CP Rosters',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health/expiring_items',
        name: 'Expiring Items',
        description: 'See who has Participation Forms, Release Forms, SSMs, CHAs, and PCTPs that are expiring or expired.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/health/ssm_exports',
        name: 'Self-Sufficiency Matrix Form Export',
        description: 'Export SSMs from any source, ETO, EPIC, and the Warehouse.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/health/ed_ip_visits',
        name: 'ED & IP Visits',
        description: 'Upload and attach ED & IP visits to patient records.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/health/ed_ip_visits',
        name: 'ED & IP Visits',
        description: 'Upload and attach ED & IP visits to patient records.',
        limitable: true,
      },
      {
        url: 'warehouse_reports/health/contact_tracing',
        name: 'Contact Tracing',
        description: 'Review and download contact tracing records.',
        limitable: false,
      },
    ],
    'Health Emergency' => [
      {
        url: 'warehouse_reports/health_emergency/testing_results',
        name: 'Testing Results',
        description: 'Review testing results.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health_emergency/medical_restrictions',
        name: 'Active Medical Restrictions',
        description: 'List active medical restrictions.',
        limitable: false,
      },
      {
        url: 'warehouse_reports/health_emergency/uploaded_results',
        name: 'Upload Test Results',
        description: 'Upload and batch add test results to clients.',
        limitable: false,
      },
    ],
  }
end

def cleanup_unused_reports
  [
    'warehouse_reports/veteran_details/actives',
    'warehouse_reports/veteran_details/entries',
    'warehouse_reports/veteran_details/exits',
  ].each do |url|
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).delete_all
  end
end

def maintain_report_definitions
  cleanup_unused_reports()
  report_list.each do |category, reports|
    reports.each do |report|
      r = GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: report[:url]).first_or_initialize
      r.report_group = category
      r.name = report[:name]
      r.description = report[:description]
      r.limitable = report[:limitable]
      r.save
    end
  end
end

def maintain_health_seeds
  Health::DataSource.where(name: 'BHCHP EPIC').first_or_create
  Health::DataSource.where(name: 'Patient Referral').first_or_create
  GrdaWarehouse::DataSource.where(short_name: 'Health').first_or_create do |ds|
    ds.name = 'Health'
    ds.authoritative = true
    ds.visible_in_window = false
    ds.authoritative_type = 'health'
    ds.save
  end

  Health::Cp.sender.first_or_create do |sender|
    sender.update(
      mmis_enrollment_name: 'COORDINATED CARE HUB',
      trace_id: 'OPENPATH00',
    )
  end
end

def maintain_data_sources
  GrdaWarehouse::DataSource.where(short_name: 'Warehouse').first_or_create do |ds|
    ds.name = 'HMIS Warehouse'
    ds.save
  end
end

# These tables are partitioned and need to have triggers and functions that
# schema loading doesn't include.  This will ensure that they exist on each deploy
def ensure_db_triggers_and_functions
  GrdaWarehouse::ServiceHistoryService.ensure_triggers
  Reporting::MonthlyReports::Base.ensure_triggers
end

ensure_db_triggers_and_functions()
setup_fake_user()
maintain_data_sources()
maintain_report_definitions()
maintain_health_seeds()

