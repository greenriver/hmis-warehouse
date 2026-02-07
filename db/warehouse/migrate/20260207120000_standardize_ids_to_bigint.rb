###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class StandardizeIdsToBigint < ActiveRecord::Migration[7.2]
  def up
    views = [
      ['client_searchable_names', 1],
      ['hmis_destination_client_latest_assessments', 1],
      ['report_disabilities', 1],
      ['report_employment_educations', 1],
      ['report_enrollments', 1],
      ['report_exits', 1],
      ['report_health_and_dvs', 1],
      ['report_income_benefits', 1],
      ['report_services', 1],
      ['combined_cohort_client_changes', 1],
      ['hmis_services', 5],
      ['hmis_households', 7],
      ['Site', 1],
      ['hmis_group_viewable_entity_projects', 3],
      ['hmis_project_access_group_members', 1],
      ['project_access_group_members', 1],
      ['project_collection_members', 1],
  ["analytics.affiliations", 1],
  ["analytics.assessment_questions", 2],
  ["analytics.assessment_results", 1],
  ["analytics.assessments", 1],
  ["analytics.cas_clients", 1],
  ["analytics.cas_opportunities", 2],
  ["analytics.cas_opportunity_categories", 2],
  ["analytics.cas_referral_contacts", 2],
  ["analytics.cas_referral_timeline_events", 1],
  ["analytics.cas_referral_users", 2],
  ["analytics.cas_referrals", 1],
  ["analytics.cas_rejection_reasons", 1],
  ["analytics.cas_steps", 1],
  ["analytics.cas_users", 1],
  ["analytics.ce_custom_referral_statuses", 1],
  ["analytics.ce_opportunities", 1],
  ["analytics.ce_participations", 1],
  ["analytics.ce_referral_decline_reasons", 1],
  ["analytics.ce_referral_notes", 1],
  ["analytics.ce_referral_participants", 1],
  ["analytics.ce_referral_step_assignments", 1],
  ["analytics.ce_referral_steps", 1],
  ["analytics.ce_referrals", 1],
  ["analytics.ce_workflow_templates", 1],
  ["analytics.ch_enrollments", 1],
  ["analytics.client_files", 1],
  ["analytics.client_geolocations", 2],
  ["analytics.client_piis", 1],
  ["analytics.client_roi_authorizations", 1],
  ["analytics.clients", 3],
  ["analytics.coc_codes", 1],
  ["analytics.cohort_client_changes", 1],
  ["analytics.cohort_client_data", 1],
  ["analytics.cohort_client_tabs", 1],
  ["analytics.cohort_clients", 2],
  ["analytics.cohort_column_metadata", 1],
  ["analytics.cohorts", 1],
  ["analytics.current_living_situations", 1],
  ["analytics.custom_assessment_answer_lookups", 1],
  ["analytics.custom_assessments", 1],
  ["analytics.custom_client_addresses", 1],
  ["analytics.custom_client_contact_points", 1],
  ["analytics.custom_client_names", 1],
  ["analytics.custom_data_element_definitions", 1],
  ["analytics.custom_data_elements", 1],
  ["analytics.custom_service_categories", 1],
  ["analytics.custom_service_types", 1],
  ["analytics.custom_services", 1],
  ["analytics.data_sources", 2],
  ["analytics.disabilities", 1],
  ["analytics.employment_educations", 1],
  ["analytics.enrollment_cocs", 1],
  ["analytics.enrollments", 2],
  ["analytics.events", 1],
  ["analytics.exits", 2],
  ["analytics.exports", 1],
  ["analytics.external_reporting_cohort_permissions", 1],
  ["analytics.external_reporting_project_permissions", 1],
  ["analytics.file_tags", 1],
  ["analytics.funders", 1],
  ["analytics.health_and_dvs", 1],
  ["analytics.hmis_case_notes", 1],
  ["analytics.hmis_client_alerts", 2],
  ["analytics.hmis_external_form_submissions", 1],
  ["analytics.hmis_form_definitions", 1],
  ["analytics.hmis_form_processors", 1],
  ["analytics.hmis_participations", 1],
  ["analytics.hmis_scan_cards", 1],
  ["analytics.hmis_staff_assignments", 2],
  ["analytics.hmis_unit_groups", 1],
  ["analytics.hmis_unit_occupancy", 1],
  ["analytics.hmis_unit_types", 1],
  ["analytics.hmis_units", 1],
  ["analytics.hud_list_items", 1],
  ["analytics.income_benefits", 1],
  ["analytics.inventories", 2],
  ["analytics.lookups_funding_sources", 1],
  ["analytics.lookups_genders", 1],
  ["analytics.lookups_living_situations", 1],
  ["analytics.lookups_project_types", 1],
  ["analytics.lookups_relationships", 1],
  ["analytics.lookups_yes_no_etcs", 1],
  ["analytics.organizations", 1],
  ["analytics.project_cocs", 2],
  ["analytics.project_groups", 1],
  ["analytics.project_project_groups", 1],
  ["analytics.projects", 2],
  ["analytics.services", 1],
  ["analytics.users", 1],
  ["analytics.warehouse_clients", 1],
  ["analytics.youth_education_statuses", 1]
]

    views.each { |view, _| drop_view view }
    safety_assured { _up }
    views.each { |view, version| create_view(view, version: version) }
  end

  def _up
    # This query identifies integer columns that should be bigints,
    # based on naming conventions and common sense exclusions.
    # It is derived from issue.sql and handles cases where the type
    # might already have been changed in some environments.
    query = <<~SQL
      SELECT
        col.table_schema,
        col.table_name,
        col.column_name
      FROM information_schema.columns col
      JOIN information_schema.tables tab ON (
        tab.table_schema = col.table_schema
        AND tab.table_name = col.table_name
        AND tab.table_catalog = col.table_catalog
      )
      WHERE col.table_catalog = current_database()
        AND data_type = 'integer'
        AND col.table_schema != 'pg_catalog'
        AND col.table_schema != 'information_schema'
        AND (column_name ~ 'id' or column_name ~ 'from' or column_name ~ 'into')
        AND SUBSTRING(column_name FROM 1 FOR 1) = LOWER(SUBSTRING(column_name FROM 1 FOR 1))
        AND column_name !~ 'override'
        AND tab.table_type != 'VIEW'
        AND col.table_name NOT IN (
          SELECT c.relname AS child
          FROM pg_inherits
          JOIN pg_class AS c ON (inhrelid=c.oid)
          JOIN pg_class as p ON (inhparent=p.oid)
        )
        AND col.table_name || '.' || col.column_name NOT IN (
          'warehouse_houseds.differentidentity',
          'warehouse_partitioned_monthly_reports.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports.project_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.client_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.destination_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.enrollment_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.organization_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.project_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.client_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.destination_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.enrollment_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.organization_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.project_id',
          'warehouse_partitioned_monthly_reports_child_only_households.client_id',
          'warehouse_partitioned_monthly_reports_child_only_households.destination_id',
          'warehouse_partitioned_monthly_reports_child_only_households.enrollment_id',
          'warehouse_partitioned_monthly_reports_child_only_households.organization_id',
          'warehouse_partitioned_monthly_reports_child_only_households.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_child_only_households.project_id',
          'warehouse_partitioned_monthly_reports_clients.client_id',
          'warehouse_partitioned_monthly_reports_clients.destination_id',
          'warehouse_partitioned_monthly_reports_clients.enrollment_id',
          'warehouse_partitioned_monthly_reports_clients.organization_id',
          'warehouse_partitioned_monthly_reports_clients.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_clients.project_id',
          'warehouse_partitioned_monthly_reports_non_veterans.client_id',
          'warehouse_partitioned_monthly_reports_non_veterans.destination_id',
          'warehouse_partitioned_monthly_reports_non_veterans.enrollment_id',
          'warehouse_partitioned_monthly_reports_non_veterans.organization_id',
          'warehouse_partitioned_monthly_reports_non_veterans.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_non_veterans.project_id',
          'warehouse_partitioned_monthly_reports_unknown.client_id',
          'warehouse_partitioned_monthly_reports_unknown.destination_id',
          'warehouse_partitioned_monthly_reports_unknown.enrollment_id',
          'warehouse_partitioned_monthly_reports_unknown.organization_id',
          'warehouse_partitioned_monthly_reports_unknown.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_unknown.project_id',
          'warehouse_partitioned_monthly_reports_veterans.client_id',
          'warehouse_partitioned_monthly_reports_veterans.destination_id',
          'warehouse_partitioned_monthly_reports_veterans.enrollment_id',
          'warehouse_partitioned_monthly_reports_veterans.organization_id',
          'warehouse_partitioned_monthly_reports_veterans.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_veterans.project_id',
          'warehouse_returns.client_id',
          'warehouse_returns.differentidentity'
        )
      ORDER BY col.table_name asc, column_name asc;
    SQL

    results = execute(query)
    results.each do |row|
      schema = row['table_schema']
      table = row['table_name']
      column = row['column_name']

      # We need to quote table and column names because some warehouse tables
      # use CamelCase (e.g. "AssessmentQuestions")
      execute "ALTER TABLE \"#{schema}\".\"#{table}\" ALTER COLUMN \"#{column}\" TYPE bigint;"
    end
  end

  def down
    # No-op: we don't want to revert bigints to integers.
  end
end
