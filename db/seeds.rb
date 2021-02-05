require 'faker'

def setup_fake_user
  unless User.find_by(email: 'noreply@example.com').present?
    # Add roles
    admin = Role.where(name: 'Admin').first_or_create
    admin.update(can_edit_users: true, can_edit_roles: true)
    dnd_staff = Role.where(name: 'CoC Staff').first_or_create

    # Add a user.  This should not be added in production
    unless Rails.env =~ /production|staging/
      initial_password = Faker::Internet.password(min_length: 16)
      user = User.new
      user.email = 'noreply@example.com'
      user.first_name = "Sample"
      user.last_name = 'Admin'
      user.password = user.password_confirmation = initial_password
      user.confirmed_at = Time.now
      user.roles = [admin, dnd_staff]
      user.save!
      puts "Created initial admin email: #{user.email}  password: #{user.password}"
    end
  end
end

# Reports
def report_list
  r_list = {
    'Operational' => [
      {
        url: 'warehouse_reports/chronic',
        name: 'Potentially Chronic Clients',
        description: 'Disabled clients who are currently homeless and have been in a project at least 12 of the last 36 months.<br />Calculated using HMIS data.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/client_in_project_during_date_range',
        name: 'Clients in a project for a given date range',
        description: 'Who was enrolled at a specific project during a given time.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/hud_chronics',
        name: 'HUD Chronic',
        description: 'Clients who meet the HUD definition of Chronically Homeless as outlined in the HMIS Glossary.<br />Calculated using self-report data from entry assessments.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/first_time_homeless',
        name: 'First Time Homeless',
        description: 'Clients who first used residential services within a given date range.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/active_veterans',
        name: 'Active Veterans for a given date range',
        description: 'Find veterans who were homeless during a date range, limitable by project type.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/disabilities',
        name: 'Enrolled clients with selected disabilities',
        description: 'Find currently enrolled clients based on disabilities',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/open_enrollments_no_service',
        name: 'Open Bed-Night Enrollments with No Recent Service',
        description: 'Client enrollments that may need to be closed.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/find_by_id',
        name: 'Bulk Find Client Details by ID',
        description: 'Lookup clients by warehouse ID. Useful for doing research outside of the warehouse and then reconnecting clients.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/chronic_housed',
        name: 'Clients Housed, Previously on the Chronic List',
        description: 'See who was housed in permanent housing after being on the chronic list.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/client_details/actives',
        name: 'Active Client Detail',
        description: 'Clients with service within a date range.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/client_details/entries',
        name: 'Client Entry Detail',
        description: 'Clients with entries into a project type within a date range.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/client_details/exits',
        name: 'Client Exit Detail',
        description: 'Clients with entries into a project type within a date range.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/expiring_consent',
        name: 'Expiring Consent',
        description: 'Clients whose consent form has expired or expires soon.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/initiatives',
        name: 'Initiatives',
        description: 'Standard reporting for initiatives, RRH, Youth, Vets...',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/touch_point_exports',
        name: 'Export Touch Points',
        description: 'Export CSVs of ETO TouchPoints.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/recidivism',
        name: 'Recidivism Report',
        description: 'Clients enrolled in PH who have service in ES or SO after the move-in-date.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/rrh',
        name: 'Rapid Rehousing Dashboard',
        description: 'Overview of RRH performance and data exploration.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/cohort_changes',
        name: 'Cohort Changes Report',
        description: 'Explore and download data related to changes in cohorts over time',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/incomes',
        name: 'Client Incomes',
        description: 'Report client incomes and sources',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/psh',
        name: 'Permanent Supportive Housing Dashboard',
        description: 'Overview of PSH performance and data exploration.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/youth_intakes',
        name: 'Homeless Youth Program Report',
        description: 'Summary counts of youth activity for state reporting.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/youth_activity',
        name: 'Youth Activity',
        description: 'Review data youth entered within a selected time period.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/client_details/last_permanent_zips',
        name: 'Last Permanent Zip Report',
        description: 'List open enrollments within a date range and the zip codes of last permanent residence.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/enrolled_project_type',
        name: 'Enrollments per project type',
        description: 'A list of clients who were enrolled in a set of project types for a given date range.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/re_entry',
        name: 'Homelessness Re-Entry',
        description: 'Details on clients who returned to homelessness after a 60 day break.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/outflow',
        name: 'Client Outflow',
        description: 'Clients who exited homelessness, or who have no recent homeless service.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/youth_follow_ups',
        name: 'Homeless Youth Follow Up Report',
        description: 'Youth who require a three month follow up.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/dv_victim_service',
        name: 'DV Victim Service Report',
        description: 'Clients fleeing domestic violence.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/ce_assessments',
        name: 'CE Assessment Report',
        description: 'Coordinated Entry assessment details.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/overlapping_coc_utilization',
        name: 'Inter-CoC Client Overlap',
        description: 'Explore enrollments for CoCs with shared clients.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/time_homeless_for_exits',
        name: 'Average Length of Time Homeless for Housed Clients',
        description: 'Time spent homeless for clients exiting homeless within a date range.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/inactive_youth_intakes',
        name: 'Inactive Youth',
        description: 'Youth with an open intake and no case management activity in the given date range.',
        limitable: true,
        health: false,
      },
      {
        url: 'client_matches',
        name: 'Process Duplicates',
        description: 'Merge identified possible duplicate clients.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/shelter',
        name: 'Emergency Shelter Dashboard',
        description: 'Overview of ES performance and data exploration.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/th',
        name: 'Transitional Housing Dashboard',
        description: 'Overview of TH performance and data exploration.',
        limitable: true,
        health: false,
      },
    ],
    'Data Quality' => [
      {
        url: 'warehouse_reports/missing_projects',
        name: 'Missing Projects ',
        description: "Shows Project IDs for enrollment records where the project isn''t in the source data.",
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/future_enrollments',
        name: 'Clients with future enrollments',
        description: 'List any clients who have enrollments in the future.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/entry_exit_service',
        name: 'Clients with Single Day Enrollments with Services',
        description: 'Clients who received services for one-day enrollments in housing related projects.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/missing_values',
        name: 'Missing values in HUD tables',
        description: 'Find the frequency of missing values in HUD Client and Enrollment tables.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/dob_entry_same',
        name: 'DOB = Entry date',
        description: "List clients who's first entry date is on their birthdate.",
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/long_standing_clients',
        name: 'Long Standing Clients',
        description: 'List clients who have been enrolled in an emergency shelter for a given number of years.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/bed_utilization',
        name: 'Bed Utilization',
        description: 'Bed utilization within the programs of an organization.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/project/data_quality',
        name: 'Project Data Quality',
        description: 'A comprehensive view into the details of how well projects meet various data quality goals.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/non_alpha_names',
        name: 'Client with odd characters in their names',
        description: "List clients who's first or last name starts with a non-alphabetic character.",
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/really_old_enrollments',
        name: 'Really Old Enrollments',
        description: 'List clients who have enrollments prior to 1970.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/length_of_stay',
        name: 'Currently enrolled clients with length of stay',
        description: 'The length of stay per program of currently enrolled clients aggregated by time interval.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/project_type_reconciliation',
        name: 'Project Type Reconciliation',
        description: 'See all projects that behave as a project type other than that in the sending system.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/anomalies',
        name: 'Client Anomalies',
        description: 'Reported anomalies and their status.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/double_enrollments',
        name: 'Doubly Enrolled Clients',
        description: 'Clients enrolled in multiple simultaneous projects of the same type.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/conflicting_client_attributes',
        name: 'Clients with Conflicting Reported Attributes',
        description: 'Identify clients whose source record attributes differ between data sources.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/hud/missing_coc_codes',
        name: 'Missing CoC Codes',
        description: 'Identify clients with missing EnrollmentCoC entries.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/hud/not_one_hohs',
        name: 'Incorrect Head of Household Counts',
        description: 'Identify households with zero or more than one Head of Household.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/hud/incorrect_move_in_dates',
        name: 'Incorrect Move-in Dates',
        description: 'Enrollments with move-in dates outside of the enrollment, or missing.',
        limitable: true,
        health: false,
      },
    ],
    'CAS' => [
      {
        url: 'warehouse_reports/manage_cas_flags',
        name: 'Manage CAS Flags',
        description: 'Use this report to bulk update <b>available in cas, disability verification on file, and HAN release on file</b>',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/cas/chronic_reconciliation',
        name: 'Chronic Reconcilliation',
        description: "See who is available in CAS but not on the chronic list, and who's not available in CAS, but is on the chronic list.",
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/cas/decision_efficiency',
        name: 'Decision Efficiency',
        description: 'Shows how quickly clients move through CAS steps.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/cas/canceled_matches',
        name: 'Canceled Matches',
        description: 'See when matches were canceled and who was involved.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/cas/decline_reason',
        name: 'Decline Reason',
        description: 'Why CAS matches were declined.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/consent',
        name: 'Consent Processing',
        description: 'Review and process consent and disability forms for potentially CAS ready clients.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/cas/process',
        name: 'Match Process',
        description: 'Export of time between steps',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/cas/apr',
        name: 'CAS APR',
        description: 'High-level counts of CAS activity for a date range',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/cas/vacancies',
        name: 'CAS Vacancies',
        description: 'CAS vacancies for a given date range',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/cas/rrh_desired',
        name: 'Clients Interested in RRH',
        description: 'Who has indicated interest in RRH but does not yet have any consent on file',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/cas/ce_assessments',
        name: 'Coordinated-Entry Assessment Status',
        description: _('Find clients who need a Coordinated Entry re-assessment.'),
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/cas/health_prioritization',
        name: 'Health Prioritization',
        description: _('Bulk set Health Prioritization for CAS.'),
        limitable: true,
        health: false,
      },
    ],
    'Audit' => [
      {
        url: 'audit_reports/agency_user',
        name: 'Agency User Audit Report',
        description: 'Report recent warehouse activity by agency users',
        limitable: false,
        health: false,
      },
      {
        url: 'audit_reports/user_login',
        name: 'User Login Report',
        description: 'Report most recent logins by users',
        limitable: false,
        health: false,
      },
    ],
    'Health: General' => [
      {
        url: 'warehouse_reports/confidential_touch_point_exports',
        name: 'Health-related TouchPoint Export',
        description: 'Export for any Confidential Health-related TouchPoints.',
        limitable: false,
        health: true,
      },
      {
        url: 'warehouse_reports/health/ssm_exports',
        name: 'Self-Sufficiency Matrix Form Export',
        description: 'Export SSMs from any source, ETO, EPIC, and the Warehouse.',
        limitable: true,
        health: true,
      },
      {
        url: 'warehouse_reports/health/ed_ip_visits',
        name: 'ED & IP Visits',
        description: 'Upload and attach ED & IP visits to patient records.',
        limitable: true,
        health: true,
      },
      {
        url: 'warehouse_reports/health/encounters',
        name: 'Encounters',
        description: 'Export Patient Encounters By Year',
        limitable: true,
        health: true,
      },
    ],
    'Health: COVID19' => [
      {
        url: 'warehouse_reports/health/contact_tracing',
        name: 'Contact Tracing',
        description: 'Review and download contact tracing records.',
        limitable: false,
        health: true,
      },
    ],
    'Health: Partner Performance' => [
      {
        url: 'warehouse_reports/health/agency_performance',
        name: 'Dashboard',
        description: 'Summary data on agency performance in the BH CP.',
        limitable: false,
        health: true,
      },
    ],
    'Health: Archive' => [
      {
        url: 'warehouse_reports/health/overview',
        name: 'Pilot Health Dashboard',
        description: 'Overview of patient metrics.',
        limitable: false,
        health: true,
      },
    ],
    'Health: ACO Performance Reports' => [
      {
        url: 'warehouse_reports/health/aco_performance',
        name: 'PCTP Signature Tracking by ACO',
        description: 'Summary data on ACO performance in the BH CP.',
        limitable: false,
        health: true,
      },
      {
        url: 'warehouse_reports/health/housing_status',
        name: 'Housing Status by ACO',
        description: 'Patient housing status report for ACOs.',
        limitable: false,
        health: true,
      },
      {
        url: 'warehouse_reports/health/housing_status_changes',
        name: 'Patient Housing Status Changes',
        description: 'Patient housing status changes report for ACOs.',
        limitable: false,
        health: true,
      },
    ],
    'Health: Member Status Tracking' => [
      {
        url: 'warehouse_reports/health/enrollments',
        name: '834: MassHealth Enrollments and Disenrollments',
        description: 'Update patient enrollments.',
        limitable: false,
        health: true,
      },
      {
        url: 'warehouse_reports/health/eligibility',
        name: '270/271: Eligibility Determination and ACO Status Changes',
        description: 'Generate and download eligibility determination files. (270/271)',
        limitable: false,
        health: true,
      },
      {
        url: 'warehouse_reports/health/member_status_reports',
        name: 'Member Status and Outreach',
        description: 'Download member status reports',
        limitable: false,
        health: true,
      },
      {
        url: 'warehouse_reports/health/patient_referrals',
        name: 'Patient Referrals',
        description: 'View and update batches of patient referrals by referral date.',
        limitable: false,
        health: true,
      },
      {
        url: 'warehouse_reports/health/cp_roster',
        name: 'CP Rosters',
        description: 'Upload CP Rosters',
        limitable: false,
        health: true,
      },
      {
        url: 'warehouse_reports/health/expiring_items',
        name: 'Expiring Items',
        description: 'See who has Participation Forms, Release Forms, SSMs, CHAs, and PCTPs that are expiring or expired.',
        limitable: true,
        health: true,
      },
      {
        url: 'warehouse_reports/health/enrollments_disenrollments',
        name: 'Enrollment-Disenrollment Files',
        description: 'Generate the monthly Enrollment/Disenrollment files for ACOs.',
        limitable: true,
        health: true,
      },
    ],
    'Health: BH CP Claims/Payments' => [
      {
        url: 'warehouse_reports/health/claims',
        name: '837: Claim Generation',
        description: 'Generate and download claims files. (837P)',
        limitable: false,
        health: true,
      },
      {
        url: 'warehouse_reports/health/premium_payments',
        name: '820: Process Premium Payments',
        description: 'Convert 820 files into human-readable Excel files',
        limitable: false,
        health: true,
      },
    ],
    'Performance' => [
      {
        url: 'performance_dashboards/overview',
        name: 'Client Performance',
        description: 'Overview of warehouse performance.',
        limitable: true,
        health: false,
      },
      {
        url: 'performance_dashboards/household',
        name: 'Household Performance',
        description: 'Overview of warehouse performance.',
        limitable: true,
        health: false,
      },
      {
        url: 'performance_dashboards/project_type',
        name: 'Project Type Performance',
        description: 'Performance by project type.',
        limitable: true,
        health: false,
      },
    ],
    'Health Emergency' => [
      {
        url: 'warehouse_reports/health_emergency/testing_results',
        name: 'Testing Results',
        description: 'Review testing results.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/health_emergency/medical_restrictions',
        name: 'Active Medical Restrictions',
        description: 'List active medical restrictions.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/health_emergency/uploaded_results',
        name: 'Upload Test Results',
        description: 'Upload and batch add test results to clients.',
        limitable: false,
        health: false,
      },
    ],
    'Exports' => [
      {
        url: 'warehouse_reports/hmis_exports',
        name: 'HUD HMIS Exports',
        description: 'Export data in the HUD standard format.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/tableau_dashboard_export',
        name: 'Tableau Dashboard Export',
        description: 'Download dashboard data sets.',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/hashed_only_hmis_exports',
        name: 'HUD HMIS CSV Exports (Hashed Only)',
        description: 'Export data in the HUD HMIS exchange format with PII hashed',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/youth_export',
        name: 'Youth Export',
        description: 'Youth data for a given time frame',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/youth_intake_export',
        name: 'Youth Intake Export',
        description: 'Export youth intake and associated data for a given time frame',
        limitable: false,
        health: false,
      },
      {
        url: 'warehouse_reports/ad_hoc_analysis',
        name: 'Ad-Hoc Analysis Export',
        description: 'Export data for offline analysis',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/ad_hoc_anon_analysis',
        name: 'Ad-Hoc Analysis Export (De-identified)',
        description: 'Export data for offline analysis, client names and ids removed',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/hmis_cross_walks',
        name: 'HMIS Cross-walk',
        description: 'Export lookup tables for warehouse record ids to HMIS ids.',
        limitable: true,
        health: false,
      },
      {
        url: 'warehouse_reports/export_covid_impact_assessments',
        name: 'COVID-19 Impact Assessment Export',
        description: 'Export Data from ETO COVID-19 impact assessments',
        limitable: true,
        health: false,
      },
    ],
    'Census' => [
      {
        url: 'censuses',
        name: 'Nightly Census',
        description: 'Daily utilization charts for projects and residential project types.',
        limitable: true,
        health: false,
      },
    ],
    'Population Dashboards' => [],
  }
  if RailsDrivers.loaded.include?(:service_scanning)
    r_list['Operational'] << {
      url: 'service_scanning/warehouse_reports/scanned_services',
      name: _('Scanned Services'),
      description: 'Pull a list of services added within a date range',
      limitable: true,
      health: false,
    }
  end
  if RailsDrivers.loaded.include?(:core_demographics_report)
    r_list['Operational'] << {
      url: 'core_demographics_report/warehouse_reports/core',
      name: 'Core Demographics',
      description: 'Summary data for client demographics across an arbitrary universe.',
      limitable: true,
      health: false,
    }
  end
  if RailsDrivers.loaded.include?(:project_scorecard)
    r_list['Performance'] << {
      url: 'project_scorecard/warehouse_reports/scorecards',
      name: 'Project Scorecard',
      description: 'Instrument for evaluating project performance.',
      limitable: true,
      health: false,
    }
  end
  if RailsDrivers.loaded.include?(:claims_reporting)
    r_list['Health: BH CP Claims/Payments'] << {
      url: 'claims_reporting/warehouse_reports/reconciliation',
      name: 'BH CP Claim Reconciliation',
      description: 'Verify payment of claims.',
      limitable: false,
      health: true,
    }
  end
  if RailsDrivers.loaded.include?(:project_pass_fail)
    r_list['Data Quality'] << {
      url: 'project_pass_fail/warehouse_reports/project_pass_fail',
      name: 'Project Pass Fail',
      description: 'Investigate data quality issues for projects',
      limitable: true,
      health: false,
    }
  end
  if RailsDrivers.loaded.include?(:health_flexible_service)
    r_list['Health: General'] << {
      url: 'health_flexible_service/warehouse_reports/member_lists',
      name: 'VPR Member Lists',
      description: 'Generate the quarterly member list files for flex services',
      limitable: true,
      health: true,
    }
  end
  if RailsDrivers.loaded.include?(:prior_living_situation)
    r_list['Operational'] << {
      url: 'prior_living_situation/warehouse_reports/prior_living_situation',
      name: 'Prior Living Situation Breakdowns',
      description: 'Details of Prior Living Situation at Entry (3.917)',
      limitable: true,
      health: false,
    }
  end
  if RailsDrivers.loaded.include?(:disability_summary)
    r_list['Operational'] << {
      url: 'disability_summary/warehouse_reports/disability_summary',
      name: 'Disability Summary',
      description: 'Details of client disabilities by CoC',
      limitable: true,
      health: false,
    }
  end
  if RailsDrivers.loaded.include?(:text_message)
    r_list['Operational'] << {
      url: 'text_message/warehouse_reports/queue',
      name: 'Text Message Queue Review',
      description: 'Insight into pending and sent Text Messages',
      limitable: false,
      health: false,
    }
  end

  if RailsDrivers.loaded.include?(:adult_only_households_sub_pop)
    r_list['Population Dashboards'] << {
      url: 'dashboards/adult_only_households',
      name: 'Adult only Households',
      description: 'Clients enrolled in homeless projects (ES, SH, SO, TH) where the household has at least one adult (18+) and no children (< 18).',
      limitable: true,
      health: false,
    }
  end
  if RailsDrivers.loaded.include?(:adults_with_children_sub_pop)
    r_list['Population Dashboards'] << {
      url: 'dashboards/adults_with_children',
      name: 'Adult and Child Households',
      description: 'Clients enrolled in homeless projects (ES, SH, SO, TH) where the household has at least one adult (18+) and one child (< 18).',
      limitable: true,
      health: false,
    }
  end
  if RailsDrivers.loaded.include?(:child_only_households_sub_pop)
    r_list['Population Dashboards'] << {
      url: 'dashboards/child_only_households',
      name: 'Child only Households',
      description: 'Clients enrolled in homeless projects (ES, SH, SO, TH) where the household has at least one child (< 18) and no adults (+ 18).',
      limitable: true,
      health: false,
    }
  end
  if RailsDrivers.loaded.include?(:clients_sub_pop)
    r_list['Population Dashboards'] << {
      url: 'dashboards/clients',
      name: 'All Clients',
      description: 'Clients enrolled in homeless projects (ES, SH, SO, TH).',
      limitable: true,
      health: false,
    }
  end
  if RailsDrivers.loaded.include?(:non_veterans_sub_pop)
    r_list['Population Dashboards'] << {
      url: 'dashboards/non_veterans',
      name: 'Non-Veteran',
      description: 'Clients enrolled in homeless projects (ES, SH, SO, TH) where the client is not a veteran.',
      limitable: true,
      health: false,
    }
  end
  if RailsDrivers.loaded.include?(:veterans_sub_pop)
    r_list['Population Dashboards'] << {
      url: 'dashboards/veterans',
      name: 'Veteran',
      description: 'Veteran clients enrolled in homeless projects (ES, SH, SO, TH).',
      limitable: true,
      health: false,
    }
  end

  r_list
end

def cleanup_unused_reports
  cleanup = [
    'warehouse_reports/veteran_details/actives',
    'warehouse_reports/veteran_details/entries',
    'warehouse_reports/veteran_details/exits',
  ]
  cleanup << 'service_scanning/warehouse_reports/scanned_services' unless RailsDrivers.loaded.include?(:service_scanning)
  cleanup << 'core_demographics_report/warehouse_reports/core' unless RailsDrivers.loaded.include?(:core_demographics_report)
  cleanup << 'claims_reporting/warehouse_reports/reconciliation' unless RailsDrivers.loaded.include?(:claims_reporting)
  cleanup << 'project_pass_fail/warehouse_reports/project_pass_fail' unless RailsDrivers.loaded.include?(:project_pass_fail)
  cleanup << 'health_flexible_service/warehouse_reports/member_lists' unless RailsDrivers.loaded.include?(:health_flexible_service)
  cleanup << 'project_scorecard/warehouse_reports/scorecards' unless RailsDrivers.loaded.include?(:project_scorecard)
  cleanup << 'prior_living_situation/warehouse_reports/prior_living_situation' unless RailsDrivers.loaded.include?(:prior_living_situation)
  cleanup << 'disability_summary/warehouse_reports/disability_summary' unless RailsDrivers.loaded.include?(:disability_summary)
  cleanup << 'text_message/warehouse_reports/queue' unless RailsDrivers.loaded.include?(:text_message)
  cleanup << 'dashboards/adult_only_households' unless RailsDrivers.loaded.include?(:adult_only_households_sub_pop)
  cleanup << 'dashboards/adults_with_children' unless RailsDrivers.loaded.include?(:adults_with_children_sub_pop)
  cleanup << 'dashboards/child_only_households' unless RailsDrivers.loaded.include?(:child_only_households_sub_pop)
  cleanup << 'dashboards/clients' unless RailsDrivers.loaded.include?(:clients_sub_pop)
  cleanup << 'dashboards/non_veterans' unless RailsDrivers.loaded.include?(:non_veterans_sub_pop)
  cleanup << 'dashboards/veterans' unless RailsDrivers.loaded.include?(:veterans_sub_pop)


  cleanup.each do |url|
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
      r.health = report[:health]
      r.save!
    end
  end
end

def health_disenrollment_reasons
  [
    { reason_code: '01', reason_description: 'Loss of Eligibility/Case Closing' },
    { reason_code: '02', reason_description: 'Newborn - As a Result of NOB' },
    { reason_code: '03', reason_description: 'Change of Plan Type (MHO Use Only)' },
    { reason_code: '04', reason_description: 'Change Category of Assistance/Ineligible' },
    { reason_code: '05', reason_description: 'Moved Out of Service Area' },
    { reason_code: '06', reason_description: 'Active TPL Segment' },
    { reason_code: '07', reason_description: 'Waivered Services (MHO Use Only)' },
    { reason_code: '08', reason_description: 'PCC/MCO Status Change' },
    { reason_code: '09', reason_description: 'PCC Status Change - Moved Out of State' },
    { reason_code: '10', reason_description: 'PCC Status Change - Moved to Other Practice' },
    { reason_code: '11', reason_description: 'MSCP Still Restricted (MHO Use Only)' },
    { reason_code: '12', reason_description: 'MSCP Restricted, No Longer Necessary' },
    { reason_code: '13', reason_description: 'Misunderstood MCO or PCC Plan Network' },
    { reason_code: '14', reason_description: 'Misunderstood MCO or PCC Plan Referral' },
    { reason_code: '15', reason_description: 'No Answer/Answering Machine When Calling Provider' },
    { reason_code: '16', reason_description: 'No Call Back from Provider' },
    { reason_code: '17', reason_description: 'Referred (by family, friend, etc.)' },
    { reason_code: '18', reason_description: 'Moved Within Service Area' },
    { reason_code: '20', reason_description: 'Language/Cultural Barrier (Interpretation Service)' },
    { reason_code: '21', reason_description: 'Language/Cultural Barrier with Office Staff' },
    { reason_code: '22', reason_description: 'Language/Cultural Barrier with Doctor' },
    { reason_code: '23', reason_description: 'Too Long to Get an Appointment for Initial Visit' },
    { reason_code: '24', reason_description: 'Too Long to Get an Appointment when Sick/Urgent' },
    { reason_code: '25', reason_description: 'Did not Like Doctor\'s Personal Manner' },
    { reason_code: '26', reason_description: 'Provider\'s Office was Unsanitary' },
    { reason_code: '27', reason_description: 'Member Did not Have Privacy for Exam' },
    { reason_code: '28', reason_description: 'Member Utilizing VA Benefits' },
    { reason_code: '29', reason_description: 'MCO Extra Programs' },
    { reason_code: '30', reason_description: 'Mass Update (MHO Use Only)' },
    { reason_code: '31', reason_description: 'Dissatisfaction with MH/SA Network' },
    { reason_code: '32', reason_description: 'Difficulty Accessing MH/SA Services' },
    { reason_code: '33', reason_description: 'Difficulty Accessing Pharmacy Service' },
    { reason_code: '34', reason_description: 'No Longer Eligible for Special Program' },
    { reason_code: '35', reason_description: 'Panel Reopened' },
    { reason_code: '36', reason_description: 'Transfer Back to PCC After Conversion to MCO' },
    { reason_code: '37', reason_description: 'Transferring as Result of Assignment' },
    { reason_code: '38', reason_description: 'Provider Profile Incorrect' },
    { reason_code: '39', reason_description: 'Provider Network Unacceptable' },
    { reason_code: '40', reason_description: 'Prefer Previous Doctor' },
    { reason_code: '41', reason_description: 'Doctor no Longer Accepting Plan' },
    { reason_code: '42', reason_description: 'Waited too Long in Waiting Room' },
    { reason_code: '43', reason_description: 'Access to Preferred Specialist' },
    { reason_code: '44', reason_description: 'Change in COA/Upgrade' },
    { reason_code: '45', reason_description: 'Doctor Refused to Join Network' },
    { reason_code: '46', reason_description: 'Assignment to Inappropriate Provider Type' },
    { reason_code: '47', reason_description: 'Dissatisfied with Healthcare' },
    { reason_code: '48', reason_description: 'Dissatisfied with Appeal Decision' },
    { reason_code: '49', reason_description: 'Death (MHO Use Only)' },
    { reason_code: '50', reason_description: 'Transportation Problem' },
    { reason_code: '51', reason_description: 'Misunderstood MCO Program' },
    { reason_code: '52', reason_description: 'Difficult to Contact Doctor' },
    { reason_code: '53', reason_description: 'Problem Receiving Emergency Care' },
    { reason_code: '54', reason_description: 'Language Barrier' },
    { reason_code: '55', reason_description: 'Poor Handicapped Access' },
    { reason_code: '56', reason_description: 'Takes too Long to Get an Appointment' },
    { reason_code: '57', reason_description: 'Did not Like Doctor' },
    { reason_code: '58', reason_description: 'Dissatisfaction with MCO Specialist Care' },
    { reason_code: '59', reason_description: 'Dissatisfaction with MH/SA Services' },
    { reason_code: '60', reason_description: 'MHMA Segment Closed with MCO Enrollment' },
    { reason_code: '61', reason_description: 'MHO Approved Disenrollment' },
    { reason_code: '62', reason_description: 'Other' },
    { reason_code: '63', reason_description: 'Health Care Needs Changed' },
    { reason_code: '64', reason_description: 'Misunderstood PCC Program' },
    { reason_code: '65', reason_description: 'Turned 65 - Loss of Eligibility (MHO Use Only)' },
    { reason_code: '66', reason_description: 'Dissatisfied with Prescribed Treatment' },
    { reason_code: '67', reason_description: 'Dissatisfied with PCP Prescription Practice' },
    { reason_code: '68', reason_description: 'Did not Meet Clinical Needs Requirements' },
    { reason_code: '69', reason_description: 'Free Transfer' },
    { reason_code: '70', reason_description: 'Medicare (MHO Use Only)' },
    { reason_code: '71', reason_description: 'LTC (MHO Use Only)' },
    { reason_code: '72', reason_description: 'MCB (MHO Use Only)' },
    { reason_code: '73', reason_description: 'Exempted from Managed Care Program' },
    { reason_code: '74', reason_description: 'Did not Like Office Staff\'s Personal Manner' },
    { reason_code: '75', reason_description: 'Received Poor Medical Treatment' },
    { reason_code: '76', reason_description: 'Problems Receiving Authorization for Referrals' },
    { reason_code: '77', reason_description: 'DSS/DYS - Related' },
    { reason_code: '78', reason_description: 'Old DYS Code - No Longer in Use' },
    { reason_code: '79', reason_description: 'Takes too Long to See Doctor in Office' },
    { reason_code: '80', reason_description: 'Request by MCO (MHO Use Only)' },
    { reason_code: '81', reason_description: 'PCC Plan Approved' },
    { reason_code: '82', reason_description: 'Improperly Enrolled' },
    { reason_code: '83', reason_description: 'Transferred as a Result of Hospice Care' },
    { reason_code: '84', reason_description: 'Per Request of Enrollment Form (HBA 3 Use)' },
    { reason_code: '85', reason_description: 'Fair Hearing Appeal Decision' },
    { reason_code: '86', reason_description: 'Opt Out of CommCare' },
    { reason_code: '87', reason_description: 'Non-Payment of Premium' },
    { reason_code: '88', reason_description: 'Multiple Providers Due to Link/Unlink' },
    { reason_code: '89', reason_description: 'Chronic Provider Access Problems' },
    { reason_code: '90', reason_description: 'Misused MCO Services (MHO Use Only)' },
    { reason_code: '91', reason_description: 'Enrolled in SCO' },
    { reason_code: '92', reason_description: 'Homeless' },
    { reason_code: '93', reason_description: 'CommCare COA Change' },
    { reason_code: '94', reason_description: 'CommCare Open Enrollment Request' },
    { reason_code: '95', reason_description: 'Loss Elig. - Special Population Member Turns 22' },
    { reason_code: '96', reason_description: 'Returned Mail' },
    { reason_code: '97', reason_description: 'Provider Practice Closed, MBHP Remains Open' },
    { reason_code: '99', reason_description: 'RS/MSCP Mass Change (MHO Use Only)' },
    { reason_code: 'AB', reason_description: 'Discharged to Nursing Facility' },
    { reason_code: 'AC', reason_description: 'Discharged to Acute Facility' },
    { reason_code: 'AD', reason_description: 'Discharged to Leave of Absence' },
    { reason_code: 'AE', reason_description: 'Transferred to a Long Term Care Facility' },
    { reason_code: 'AF', reason_description: 'Member No Longer Wants Hospice Services (Revocation)' },
    { reason_code: 'AG', reason_description: 'Declined Services (Nursing, etc.)' },
    { reason_code: 'AH', reason_description: 'Transferred to MCO Special Program' },
    { reason_code: 'AI', reason_description: 'Enrolled in All-Inclusive Managed Care Plan' },
    { reason_code: 'AJ', reason_description: 'Enrolled in PACE' },
    { reason_code: 'AK', reason_description: 'Discharged to Home/Community' },
    { reason_code: 'AL', reason_description: 'Discharged to Rest Home' },
    { reason_code: 'AM', reason_description: 'Left Against Medical Advice' },
    { reason_code: 'AN', reason_description: 'Member Opt-out' },
    { reason_code: 'AP', reason_description: 'Member Enrolled in HCBS Waiver' },
    { reason_code: 'AQ', reason_description: 'ICF-MR Admission' },
    { reason_code: 'AR', reason_description: 'Loss of Medicare A and/or B' },
    { reason_code: 'AS', reason_description: 'Member enrolled in Medicare Part C (Medicare Advantage)' },
    { reason_code: 'AT', reason_description: 'Change of Medicare Part D Plan' },
    { reason_code: 'AZ', reason_description: 'Default Stop Reason Code' },
    { reason_code: 'B6', reason_description: 'CommP - Enrollee Requested Change' },
    { reason_code: 'B7', reason_description: 'CommP - ACO/MCO Requested Change' },
    { reason_code: 'B8', reason_description: 'CommP - Declined' },
    { reason_code: 'B9', reason_description: 'CommP - Unreachable' },
    { reason_code: 'BA', reason_description: 'CommP - Disengaged' },
    { reason_code: 'BB', reason_description: 'CommP - Moved out of Geographic Area' },
    { reason_code: 'BC', reason_description: 'CommP - Graduated' },
    { reason_code: 'BD', reason_description: 'CommP - Medical Exception' },
    { reason_code: 'BH', reason_description: 'CommP - ACCS Aid Cat Change' },
    { reason_code: 'BI', reason_description: 'CommP - AUTO-Re-Enrollment - ACCS Special Rule' },
    { reason_code: 'BJ', reason_description: 'CommP - AUTO-Transfer due ACCS enrollment (change from ACCS to PACC)' },
    { reason_code: 'BK', reason_description: 'CommP - AUTO-Transfer due Addition of MC Eligibility (ACCS2 to ACCS1 or PACC2 to PACC1)' },
    { reason_code: 'BL', reason_description: 'CommP - AUTO-Disenrollment due PACT enrollment' },
    { reason_code: 'BM', reason_description: 'CommP - AUTO-Disenrollment due ACCS enrollment' },
    { reason_code: 'EO', reason_description: 'Service Area Restriction Enrollment Override' },
    { reason_code: 'P0', reason_description: 'PSFE - Admin' },
    { reason_code: 'P1', reason_description: 'PSFE - Moved outside of the Service Area in which the MCO operates' },
    { reason_code: 'P2', reason_description: 'PSFE - MCO has not provided access to health care providers that meets enrollee health care needs' },
    { reason_code: 'P3', reason_description: 'PSFE - Enrollee is homeless, and MCO cannot accommodate the geographic needs of the member' },
    { reason_code: 'P4', reason_description: 'PSFE - MCO substantially violated a material provision of its contract in relation to the enrollee' },
    { reason_code: 'P5', reason_description: 'PSFE - MassHealth imposes a sanction on the MCO which allow enrollment termination without cause' },
    { reason_code: 'SC', reason_description: 'Member Opt-out from SCO' },
    { reason_code: 'TB', reason_description: 'Auto-Disenroll - PCCB-CPCCB and ACOB No Longer Affiliated' },
    { reason_code: 'Z0', reason_description: 'Auto-Disenroll - Death' },
    { reason_code: 'Z1', reason_description: 'Auto-Disenroll - Ineligible Aid Cat/Loss of Medicaid Eligibility' },
    { reason_code: 'Z2', reason_description: 'Auto-Disenroll - Comprehensive Verified TPL' },
    { reason_code: 'Z3', reason_description: 'Auto-Disenroll - Medicare A or B' },
    { reason_code: 'Z4', reason_description: 'Auto-Disenroll - Mutually Exclusive Program' },
    { reason_code: 'Z5', reason_description: 'BATCH - Dental Eligibility Review' },
    { reason_code: 'Z6', reason_description: 'Auto-Disenroll - Excluded from Managed Care' },
    { reason_code: 'Z7', reason_description: 'Auto-Disenroll - Active Spenddown' },
    { reason_code: 'Z8', reason_description: 'Auto-Disenroll - Maximum Age - Loss of Eligibility' },
    { reason_code: 'Z9', reason_description: 'Auto-Disenroll - Active Long Term Care' },
    { reason_code: 'ZA', reason_description: 'Auto-Disenroll - Newborn - As a Result of NOB' },
    { reason_code: 'ZB', reason_description: 'Auto-Disenroll - LTC Benefit Exhaustion' },
    { reason_code: 'ZC', reason_description: 'Auto-Disenroll - Min Age For PGM Enrollment Not Met' },
    { reason_code: 'ZD', reason_description: 'Auto-Disenroll - AR03 Temporary Eligibility' },
    { reason_code: 'ZE', reason_description: 'Auto-Disenroll - Member Opt-out' },
    { reason_code: 'ZF', reason_description: 'Auto disenrollment - ICF-MR Admission' },
    { reason_code: 'ZG', reason_description: 'Auto disenrollment - Loss of Medicare A and/or B' },
    { reason_code: 'ZH', reason_description: 'Auto Disenroll - Member gained Medicare Part C (Medicare Advantage)' },
    { reason_code: 'ZI', reason_description: 'NON-STD to STD-Disabled Transfer' },
    { reason_code: 'ZJ', reason_description: 'Auto Disenroll - Change of Medicare Part D Plan' },
    { reason_code: 'ZK', reason_description: 'Auto-Disenroll - Member enrolled in HCBS Waiver' },
    { reason_code: 'ZL', reason_description: 'Auto-Disenroll - Higher Aid Category Forced Transfer' },
    { reason_code: 'ZM', reason_description: 'Auto-Disenroll - Mass Transfer' },
    { reason_code: 'ZN', reason_description: 'Plan Change - DT Less Rich Aid Cat Forced Transfer' },
    { reason_code: 'ZT', reason_description: 'Auto-Disenroll - Loss of TPL/Medicare' },
  ].freeze
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

  health_disenrollment_reasons.each do |reason|
    Health::DisenrollmentReason.where(reason).first_or_create
  end
end

def maintain_data_sources
  GrdaWarehouse::DataSource.where(short_name: 'Warehouse').first_or_create do |ds|
    ds.name = 'HMIS Warehouse'
    ds.save
  end
end

def maintain_lookups
  HUD.cocs.each do |code, name|
    coc = GrdaWarehouse::Lookups::CocCode.where(coc_code: code).first_or_initialize
    coc.update(official_name: name)
  end
  GrdaWarehouse::Lookups::YesNoEtc.transaction do
    GrdaWarehouse::Lookups::YesNoEtc.delete_all
    columns = [:value, :text]
    GrdaWarehouse::Lookups::YesNoEtc.import(columns, HUD.no_yes_reasons_for_missing_data_options.to_a)
  end
  GrdaWarehouse::Lookups::LivingSituation.transaction do
    GrdaWarehouse::Lookups::LivingSituation.delete_all
    columns = [:value, :text]
    GrdaWarehouse::Lookups::LivingSituation.import(columns, HUD.living_situations.to_a)
  end
  GrdaWarehouse::Lookups::ProjectType.transaction do
    GrdaWarehouse::Lookups::ProjectType.delete_all
    columns = [:value, :text]
    GrdaWarehouse::Lookups::ProjectType.import(columns, HUD.project_types.to_a)
  end
  GrdaWarehouse::Lookups::Ethnicity.transaction do
    GrdaWarehouse::Lookups::Ethnicity.delete_all
    columns = [:value, :text]
    GrdaWarehouse::Lookups::Ethnicity.import(columns, HUD.no_yes_reasons_for_missing_data_options.to_a)
  end
  GrdaWarehouse::Lookups::FundingSource.transaction do
    GrdaWarehouse::Lookups::FundingSource.delete_all
    columns = [:value, :text]
    GrdaWarehouse::Lookups::FundingSource.import(columns, HUD.funding_sources.to_a)
  end
  GrdaWarehouse::Lookups::Gender.transaction do
    GrdaWarehouse::Lookups::Gender.delete_all
    columns = [:value, :text]
    GrdaWarehouse::Lookups::Gender.import(columns, HUD.genders.to_a)
  end
  GrdaWarehouse::Lookups::TrackingMethod.transaction do
    GrdaWarehouse::Lookups::TrackingMethod.delete_all
    columns = [:value, :text]
    GrdaWarehouse::Lookups::TrackingMethod.import(columns, HUD.tracking_methods.to_a)
  end
  GrdaWarehouse::Lookups::Relationship.transaction do
    GrdaWarehouse::Lookups::Relationship.delete_all
    columns = [:value, :text]
    GrdaWarehouse::Lookups::Relationship.import(columns, HUD.relationships_to_hoh.to_a)
  end
end

def install_shapes
  if GrdaWarehouse::Shape::ZipCode.none? || GrdaWarehouse::Shape::CoC.none?
    begin
      Rake::Task['grda_warehouse:get_shapes'].invoke
    rescue Exception
    end
  end
end

# These tables are partitioned and need to have triggers and functions that
# schema loading doesn't include.  This will ensure that they exist on each deploy
def ensure_db_triggers_and_functions
  GrdaWarehouse::ServiceHistoryService.ensure_triggers
  Reporting::MonthlyReports::Base.ensure_triggers
end

def maintain_system_groups
  AccessGroup.maintain_system_groups
end

ensure_db_triggers_and_functions()
setup_fake_user() if Rails.env.development?
maintain_data_sources()
maintain_report_definitions()
maintain_health_seeds()
install_shapes()
maintain_lookups()
maintain_system_groups()
