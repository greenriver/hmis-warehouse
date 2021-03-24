###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class ReportDefinition < GrdaWarehouseBase
    has_many :group_viewable_entities, as: :entity, class_name: 'GrdaWarehouse::GroupViewableEntity'

    scope :enabled, -> do
      where(enabled: true)
    end

    scope :non_health, -> do
      where(health: false)
    end

    scope :viewable_by, ->(user) do
      return none unless user

      if user.can_view_all_reports?
        current_scope
      elsif user.can_view_assigned_reports?
        joins(:group_viewable_entities).
          merge(GrdaWarehouse::GroupViewableEntity.viewable_by(user))
      else
        none
      end
    end

    scope :assignable_by, ->(user) do
      return none unless user

      if user.can_assign_reports?
        current_scope
      else
        none
      end
    end

    scope :ordered, -> do
      order(weight: :asc, name: :asc)
    end

    def self.maintain_report_definitions
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

    def new_report?
      created_at > Date.current - 2.weeks
    end

    # Reports
    def self.report_list
      r_list = {
        'Public' => [],
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
          # {
          #   url: 'performance_dashboards/household',
          #   name: 'Household Performance',
          #   description: 'Overview of warehouse performance.',
          #   limitable: true,
          #   health: false,
          # },
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
        r_list['Health: BH CP Claims/Payments'] << {
          url: 'claims_reporting/warehouse_reports/performance',
          name: 'BH CP Performance',
          description: 'Performance metrics based on paid MassHealth claims.',
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
      if RailsDrivers.loaded.include?(:destination_report)
        r_list['Operational'] << {
          url: 'destination_report/warehouse_reports/reports',
          name: 'Destination Breakdowns',
          description: 'Details of Destination at Exit (3.12.1)',
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
      if RailsDrivers.loaded.include?(:census_tracking)
        r_list['Operational'] << {
          url: 'census_tracking/warehouse_reports/census_trackers',
          name: 'Census Tracking Worksheet',
          description: 'Breakdown of PIT Census data for chosen date',
          limitable: true,
          health: false,
        }
      end
      if RailsDrivers.loaded.include?(:public_reports)
        # Only attempt this if the driver is loaded, and only install the reports
        # if the bucket can be setup correctly
        if PublicReports::Report.new.ready_public_s3_bucket!
          r_list['Public'] << {
            url: 'public_reports/warehouse_reports/point_in_time',
            name: 'Public Point-in-Time Report Generator',
            description: 'Use this to review and publish Point-in-Time charts for public consumption.',
            limitable: false,
            health: false,
          }
          r_list['Public'] << {
            url: 'public_reports/warehouse_reports/pit_by_month',
            name: 'Public Point-in-Time by Month Report Generator',
            description: 'Use this to review and publish Point-in-Time by month charts for public consumption.',
            limitable: false,
            health: false,
          }
          r_list['Public'] << {
            url: 'public_reports/warehouse_reports/public_configs',
            name: 'Public Report Configuration',
            description: 'Settings for colors, fonts, etc. related to reports which can be published publicly.',
            limitable: false,
            health: false,
          }
          r_list['Public'] << {
            url: 'public_reports/warehouse_reports/number_housed',
            name: 'Public Number Housed Report Generator',
            description: 'Use this to review and publish the number of clients housed for public consumption.',
            limitable: false,
            health: false,
          }
          r_list['Public'] << {
            url: 'public_reports/warehouse_reports/homeless_count',
            name: 'Public Number Homeless Report Generator',
            description: 'Use this to review and publish the number of homeless clients for public consumption.',
            limitable: false,
            health: false,
          }
          r_list['Public'] << {
            url: 'public_reports/warehouse_reports/homeless_count_comparison',
            name: 'Public Percent Homeless Comparison Report Generator',
            description: 'Use this to review and publish the change of homeless clients for public consumption.',
            limitable: false,
            health: false,
          }
        end
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
      if RailsDrivers.loaded.include?(:income_benefits_report)
        r_list['Operational'] << {
          url: 'income_benefits_report/warehouse_reports/report',
          name: 'Income, Non-Cash Benefits, Health Insurance Report',
          description: 'Performance indicators and aggregate statistics for income, benefits, and health insurance from HMIS data.',
          limitable: true,
          health: false,
        }
      end

      r_list
    end

    def self.cleanup_unused_reports
      cleanup = [
        'warehouse_reports/veteran_details/actives',
        'warehouse_reports/veteran_details/entries',
        'warehouse_reports/veteran_details/exits',
        'performance_dashboards/household',
      ]
      cleanup << 'service_scanning/warehouse_reports/scanned_services' unless RailsDrivers.loaded.include?(:service_scanning)
      cleanup << 'core_demographics_report/warehouse_reports/core' unless RailsDrivers.loaded.include?(:core_demographics_report)
      unless RailsDrivers.loaded.include?(:claims_reporting)
        cleanup << 'claims_reporting/warehouse_reports/reconciliation'
        cleanup << 'claims_reporting/warehouse_reports/performance'
      end
      cleanup << 'project_pass_fail/warehouse_reports/project_pass_fail' unless RailsDrivers.loaded.include?(:project_pass_fail)
      cleanup << 'health_flexible_service/warehouse_reports/member_lists' unless RailsDrivers.loaded.include?(:health_flexible_service)
      cleanup << 'project_scorecard/warehouse_reports/scorecards' unless RailsDrivers.loaded.include?(:project_scorecard)
      cleanup << 'prior_living_situation/warehouse_reports/prior_living_situation' unless RailsDrivers.loaded.include?(:prior_living_situation)
      cleanup << 'destination_report/warehouse_reports/reports' unless RailsDrivers.loaded.include?(:destination_report)
      cleanup << 'disability_summary/warehouse_reports/disability_summary' unless RailsDrivers.loaded.include?(:disability_summary)
      cleanup << 'text_message/warehouse_reports/queue' unless RailsDrivers.loaded.include?(:text_message)
      unless RailsDrivers.loaded.include?(:public_reports)
        cleanup << 'public_reports/warehouse_reports/point_in_time'
        cleanup << 'public_reports/warehouse_reports/pit_by_month'
        cleanup << 'public_reports/warehouse_reports/public_configs'
        cleanup << 'public_reports/warehouse_reports/number_housed'
        cleanup << 'public_reports/warehouse_reports/homeless_count'
        cleanup << 'public_reports/warehouse_reports/homeless_count_comparison'
      end
      cleanup << 'dashboards/adult_only_households' unless RailsDrivers.loaded.include?(:adult_only_households_sub_pop)
      cleanup << 'dashboards/adults_with_children' unless RailsDrivers.loaded.include?(:adults_with_children_sub_pop)
      cleanup << 'dashboards/child_only_households' unless RailsDrivers.loaded.include?(:child_only_households_sub_pop)
      cleanup << 'dashboards/clients' unless RailsDrivers.loaded.include?(:clients_sub_pop)
      cleanup << 'dashboards/non_veterans' unless RailsDrivers.loaded.include?(:non_veterans_sub_pop)
      cleanup << 'dashboards/veterans' unless RailsDrivers.loaded.include?(:veterans_sub_pop)
      cleanup << 'census_tracking/warehouse_reports/census_trackers' unless RailsDrivers.loaded.include?(:census_tracking)
      cleanup << 'income_benefits_report/warehouse_reports/report' unless RailsDrivers.loaded.include?(:income_benefits_report)

      cleanup.each do |url|
        GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).delete_all
      end
    end
  end
end
