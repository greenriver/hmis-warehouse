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

    field :delete_service, mutation: Mutations::DeleteService
    field :bulk_assign_service, mutation: Mutations::BulkAssignService
    field :bulk_remove_service, mutation: Mutations::BulkRemoveService

    field :create_service_type, mutation: Mutations::CreateServiceType
    field :delete_service_type, mutation: Mutations::DeleteServiceType
    field :update_service_type, mutation: Mutations::UpdateServiceType

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
    field :delete_custom_case_note, mutation: Mutations::DeleteCustomCaseNote

    field :merge_clients, mutation: Mutations::MergeClients
    field :bulk_merge_clients, mutation: Mutations::BulkMergeClients

    field :create_form_definition, mutation: Mutations::CreateFormDefinition
    field :update_form_definition, mutation: Mutations::UpdateFormDefinition
    field :delete_form_definition, mutation: Mutations::DeleteFormDefinition
    field :publish_form_definition, mutation: Mutations::PublishFormDefinition
    field :create_next_draft_form_definition, mutation: Mutations::CreateNextDraftFormDefinition

    field :create_form_rule, mutation: Mutations::CreateFormRule
    field :delete_form_rule, mutation: Mutations::DeleteFormRule
    field :update_form_rule, mutation: Mutations::UpdateFormRule, deprecation_reason: 'Replaced with DeleteFormRule'

    field :create_project_config, mutation: Mutations::CreateProjectConfig
    field :update_project_config, mutation: Mutations::UpdateProjectConfig
    field :delete_project_config, mutation: Mutations::DeleteProjectConfig

    field :create_scan_card_code, mutation: Mutations::CreateScanCardCode
    field :delete_scan_card_code, mutation: Mutations::DeleteScanCardCode
    field :restore_scan_card_code, mutation: Mutations::RestoreScanCardCode

    field :create_client_alert, mutation: Mutations::CreateClientAlert
    field :delete_client_alert, mutation: Mutations::DeleteClientAlert

    field :update_external_form_submission, mutation: Mutations::UpdateExternalFormSubmission
    field :delete_external_form_submission, mutation: Mutations::DeleteExternalFormSubmission
    field :bulk_review_external_submissions, mutation: Mutations::BulkReviewExternalSubmissions
    field :refresh_external_submissions, mutation: Mutations::RefreshExternalSubmissions

    field :assign_staff, mutation: Mutations::AssignStaff
    field :unassign_staff, mutation: Mutations::UnassignStaff
  end
end
