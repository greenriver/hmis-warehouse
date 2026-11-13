###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DropRemovedHealthModelTables < ActiveRecord::Migration[8.1]
  def up
    # Core BH-CP / patient model tables
    drop_table :accountable_care_organizations, if_exists: true
    drop_table :agencies, if_exists: true
    drop_table :agency_patient_referrals, if_exists: true
    drop_table :agency_users, if_exists: true
    drop_table :any_careplans, if_exists: true
    drop_table :backup_plans, if_exists: true
    drop_table :ca_assessments, if_exists: true
    drop_table :careplan_equipment, if_exists: true
    drop_table :careplan_services, if_exists: true
    drop_table :careplans, if_exists: true
    drop_table :claims, if_exists: true
    drop_table :comprehensive_health_assessments, if_exists: true
    drop_table :contacts, if_exists: true
    drop_table :coordination_teams, if_exists: true
    drop_table :cp_member_files, if_exists: true
    drop_table :data_sources, if_exists: true
    drop_table :disenrollment_reasons, if_exists: true
    drop_table :document_exports, if_exists: true
    drop_table :ed_ip_visit_files, if_exists: true
    drop_table :ed_ip_visits, if_exists: true
    drop_table :eligibility_inquiries, if_exists: true
    drop_table :eligibility_responses, if_exists: true
    drop_table :encounter_records, if_exists: true
    drop_table :encounter_reports, if_exists: true
    drop_table :enrollment_reasons, if_exists: true
    drop_table :enrollment_rosters, if_exists: true
    drop_table :enrollments, if_exists: true
    drop_table :equipment, if_exists: true
    drop_table :health_goals, if_exists: true
    drop_table :housing_statuses, if_exists: true
    drop_table :hrsn_screenings, if_exists: true
    drop_table :loaded_ed_ip_visits, if_exists: true
    drop_table :member_status_report_patients, if_exists: true
    drop_table :member_status_reports, if_exists: true
    drop_table :participation_forms, if_exists: true
    drop_table :patient_referral_imports, if_exists: true
    drop_table :patient_referrals, if_exists: true
    drop_table :premium_payments, if_exists: true
    drop_table :problems, if_exists: true
    drop_table :qualifying_activities, if_exists: true
    drop_table :release_forms, if_exists: true
    drop_table :rosters, if_exists: true
    drop_table :scheduled_documents, if_exists: true
    drop_table :sdh_case_management_notes, if_exists: true
    drop_table :self_sufficiency_matrix_forms, if_exists: true
    drop_table :services, if_exists: true
    drop_table :signable_documents, if_exists: true
    drop_table :signature_requests, if_exists: true
    drop_table :ssm_exports, if_exists: true
    drop_table :status_dates, if_exists: true
    drop_table :team_members, if_exists: true
    drop_table :teams, if_exists: true
    drop_table :transaction_acknowledgements, if_exists: true
    drop_table :user_care_coordinators, if_exists: true

    # Epic import tables
    drop_table :appointments, if_exists: true
    drop_table :epic_careplans, if_exists: true
    drop_table :epic_case_note_qualifying_activities, if_exists: true
    drop_table :epic_case_notes, if_exists: true
    drop_table :epic_chas, if_exists: true
    drop_table :epic_goals, if_exists: true
    drop_table :epic_housing_statuses, if_exists: true
    drop_table :epic_patients, if_exists: true
    drop_table :epic_qualifying_activities, if_exists: true
    drop_table :epic_ssms, if_exists: true
    drop_table :epic_team_members, if_exists: true
    drop_table :epic_thrives, if_exists: true
    drop_table :medications, if_exists: true
    drop_table :vaccinations, if_exists: true
    drop_table :visits, if_exists: true

    # Contact tracing (Health::Tracing:: — also deleted in df5734f0d4;
    # NOT the GrdaWarehouse::HealthEmergency tables, which are untouched)
    drop_table :tracing_cases, if_exists: true
    drop_table :tracing_contacts, if_exists: true
    drop_table :tracing_locations, if_exists: true
    drop_table :tracing_results, if_exists: true
    drop_table :tracing_site_leaders, if_exists: true
    drop_table :tracing_staffs, if_exists: true

    # Claims-adjacent tables (not the already-handled claims_reporting_* group)
    drop_table :claims_amount_paid_location_month, if_exists: true
    drop_table :claims_claim_volume_location_month, if_exists: true
    drop_table :claims_ed_nyu_severity, if_exists: true
    drop_table :claims_roster, if_exists: true
    drop_table :claims_top_conditions, if_exists: true
    drop_table :claims_top_ip_conditions, if_exists: true
    drop_table :claims_top_providers, if_exists: true

    # Removed drivers: health_comprehensive_assessment, health_flexible_service,
    # health_pctp, health_qa_factory, health_thrive_assessment, claims_reporting (hl7)
    drop_table :hca_assessments, if_exists: true
    drop_table :hca_medications, if_exists: true
    drop_table :hca_sud_treatments, if_exists: true
    drop_table :health_flexible_service_follow_ups, if_exists: true
    drop_table :health_flexible_service_vprs, if_exists: true
    drop_table :pctp_care_goals, if_exists: true
    drop_table :pctp_careplans, if_exists: true
    drop_table :pctp_needs, if_exists: true
    drop_table :health_qa_factory_factories, if_exists: true
    drop_table :thrive_assessments, if_exists: true
    drop_table :hl7_value_set_codes, if_exists: true

    # Dropped last: referenced by FK from comprehensive_health_assessments,
    # health_goals, participation_forms, release_forms,
    # sdh_case_management_notes, and team_members (all dropped above)
    drop_table :patients, if_exists: true
    drop_table :health_files, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
