###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RemoveHealthOnlyColumns < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      remove_column :roles, :health_role
      remove_column :roles, :can_administer_health
      remove_column :roles, :can_edit_client_health
      remove_column :roles, :can_view_client_health
      remove_column :roles, :can_view_aggregate_health
      remove_column :roles, :can_manage_health_agency
      remove_column :roles, :can_approve_patient_assignments
      remove_column :roles, :can_manage_claims
      remove_column :roles, :can_manage_all_patients
      remove_column :roles, :can_manage_patients_for_own_agency
      remove_column :roles, :can_manage_care_coordinators
      remove_column :roles, :can_approve_cha
      remove_column :roles, :can_approve_ssm
      remove_column :roles, :can_approve_release
      remove_column :roles, :can_approve_participation
      remove_column :roles, :can_approve_careplan
      remove_column :roles, :can_edit_all_patient_items
      remove_column :roles, :can_edit_patient_items_for_own_agency
      remove_column :roles, :can_create_care_plans_for_own_agency
      remove_column :roles, :can_view_all_patients
      remove_column :roles, :can_view_patients_for_own_agency
      remove_column :roles, :can_add_case_management_notes
      remove_column :roles, :can_manage_accountable_care_organizations
      remove_column :roles, :can_view_member_health_reports
      remove_column :roles, :can_unsubmit_submitted_claims
      remove_column :roles, :can_edit_health_emergency_contact_tracing
    end
  end

  def down
    safety_assured do
      add_column :roles, :can_edit_health_emergency_contact_tracing, :boolean, default: false
      add_column :roles, :can_unsubmit_submitted_claims, :boolean, default: false
      add_column :roles, :can_view_member_health_reports, :boolean, default: false
      add_column :roles, :can_manage_accountable_care_organizations, :boolean, default: false
      add_column :roles, :can_add_case_management_notes, :boolean, default: false
      add_column :roles, :can_view_patients_for_own_agency, :boolean, default: false
      add_column :roles, :can_view_all_patients, :boolean, default: false
      add_column :roles, :can_create_care_plans_for_own_agency, :boolean, default: false
      add_column :roles, :can_edit_patient_items_for_own_agency, :boolean, default: false
      add_column :roles, :can_edit_all_patient_items, :boolean, default: false
      add_column :roles, :can_approve_careplan, :boolean, default: false
      add_column :roles, :can_approve_participation, :boolean, default: false
      add_column :roles, :can_approve_release, :boolean, default: false
      add_column :roles, :can_approve_ssm, :boolean, default: false
      add_column :roles, :can_approve_cha, :boolean, default: false
      add_column :roles, :can_manage_care_coordinators, :boolean, default: false
      add_column :roles, :can_manage_patients_for_own_agency, :boolean, default: false
      add_column :roles, :can_manage_all_patients, :boolean, default: false
      add_column :roles, :can_manage_claims, :boolean, default: false
      add_column :roles, :can_approve_patient_assignments, :boolean, default: false
      add_column :roles, :can_manage_health_agency, :boolean, default: false
      add_column :roles, :can_view_aggregate_health, :boolean, default: false
      add_column :roles, :can_view_client_health, :boolean, default: false
      add_column :roles, :can_edit_client_health, :boolean, default: false
      add_column :roles, :can_administer_health, :boolean, default: false
      add_column :roles, :health_role, :boolean, default: false, null: false
    end
  end
end
