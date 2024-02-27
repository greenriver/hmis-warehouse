###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::MutationType < Types::BaseObject
    skip_activity_log
    field :update_client_image, mutation: Mutations::UpdateClientImage
    field :delete_client_image, mutation: Mutations::DeleteClientImage
    field :delete_client_file, mutation: Mutations::DeleteClientFile
    field :update_relationship_to_ho_h, mutation: Mutations::UpdateRelationshipToHoH

    field :delete_enrollment, mutation: Mutations::DeleteEnrollment
    field :delete_organization, mutation: Mutations::DeleteOrganization
    field :delete_project, mutation: Mutations::DeleteProject
    field :delete_project_coc, mutation: Mutations::DeleteProjectCoc
    field :delete_funder, mutation: Mutations::DeleteFunder
    field :delete_inventory, mutation: Mutations::DeleteInventory
    field :delete_client, mutation: Mutations::DeleteClient
    field :delete_ce_assessment, mutation: Mutations::DeleteCeAssessment
    field :delete_ce_event, mutation: Mutations::DeleteCeEvent
    field :delete_current_living_situation, mutation: Mutations::DeleteCurrentLivingSituation
    field :delete_hmis_participation, mutation: Mutations::DeleteHmisParticipation
    field :delete_ce_participation, mutation: Mutations::DeleteCeParticipation

    field :create_units, mutation: Mutations::CreateUnits
    field :update_units, mutation: Mutations::UpdateUnits
    field :delete_units, mutation: Mutations::DeleteUnits

    field :create_service, mutation: Mutations::CreateService
    field :delete_service, mutation: Mutations::DeleteService
    field :update_bed_nights, mutation: Mutations::UpdateBedNights
    field :bulk_assign_service, mutation: Mutations::BulkAssignService

    field :save_assessment, mutation: Mutations::SaveAssessment
    field :submit_assessment, mutation: Mutations::SubmitAssessment
    field :delete_assessment, mutation: Mutations::DeleteAssessment
    field :submit_household_assessments, mutation: Mutations::SubmitHouseholdAssessments
    field :create_direct_upload, mutation: Mutations::CreateDirectUpload

    field :add_recent_item, mutation: Mutations::AddRecentItem
    field :clear_recent_items, mutation: Mutations::ClearRecentItems
    field :submit_form, mutation: Mutations::SubmitForm

    field :clear_mci, mutation: Mutations::AcHmis::ClearMci
    field :void_referral_request, mutation: Mutations::AcHmis::VoidReferralRequest
    field :update_referral_posting, mutation: Mutations::AcHmis::UpdateReferralPosting
    field :create_outgoing_referral_posting, mutation: Mutations::AcHmis::CreateOutgoingReferralPosting
    field :delete_custom_case_note, mutation: Mutations::DeleteCustomCaseNote

    field :merge_clients, mutation: Mutations::MergeClients
    field :bulk_merge_clients, mutation: Mutations::BulkMergeClients

    field :create_form_definition, mutation: Mutations::CreateFormDefinition
    field :update_form_definition, mutation: Mutations::UpdateFormDefinition
    field :delete_form_definition, mutation: Mutations::DeleteFormDefinition

    field :create_form_rule, mutation: Mutations::CreateFormRule
    field :update_form_rule, mutation: Mutations::UpdateFormRule

    field :create_auto_exit_config, mutation: Mutations::CreateAutoExitConfig
    field :update_auto_exit_config, mutation: Mutations::UpdateAutoExitConfig
    field :delete_auto_exit_config, mutation: Mutations::DeleteAutoExitConfig

    field :create_scan_card_code, mutation: Mutations::CreateScanCardCode
    field :delete_scan_card_code, mutation: Mutations::DeleteScanCardCode
    field :restore_scan_card_code, mutation: Mutations::RestoreScanCardCode

    field :create_client_alert, mutation: Mutations::CreateClientAlert
    field :delete_client_alert, mutation: Mutations::DeleteClientAlert
  end
end
