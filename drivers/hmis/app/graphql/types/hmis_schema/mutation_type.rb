###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::MutationType < Types::BaseObject
    field :update_client_image, mutation: Mutations::UpdateClientImage
    field :delete_client_image, mutation: Mutations::DeleteClientImage
    field :delete_client_file, mutation: Mutations::DeleteClientFile
    field :create_enrollment, mutation: Mutations::CreateEnrollment
    field :add_household_members_to_enrollment, mutation: Mutations::AddHouseholdMembersToEnrollment
    field :update_relationship_to_ho_h, mutation: Mutations::UpdateRelationshipToHoH
    field :delete_enrollment, mutation: Mutations::DeleteEnrollment
    field :delete_organization, mutation: Mutations::DeleteOrganization
    field :delete_project, mutation: Mutations::DeleteProject
    field :delete_project_coc, mutation: Mutations::DeleteProjectCoc
    field :delete_funder, mutation: Mutations::DeleteFunder
    field :delete_inventory, mutation: Mutations::DeleteInventory
    field :delete_client, mutation: Mutations::DeleteClient

    field :create_units, mutation: Mutations::CreateUnits
    field :create_beds, mutation: Mutations::CreateBeds
    field :update_units, mutation: Mutations::UpdateUnits
    field :update_beds, mutation: Mutations::UpdateBeds
    field :delete_units, mutation: Mutations::DeleteUnits
    field :delete_beds, mutation: Mutations::DeleteBeds

    field :create_service, mutation: Mutations::CreateService
    field :update_service, mutation: Mutations::UpdateService
    field :delete_service, mutation: Mutations::DeleteService
    field :save_assessment, mutation: Mutations::SaveAssessment
    field :submit_assessment, mutation: Mutations::SubmitAssessment
    field :delete_assessment, mutation: Mutations::DeleteAssessment
    field :submit_household_assessments, mutation: Mutations::SubmitHouseholdAssessments
    field :create_direct_upload, mutation: Mutations::CreateDirectUpload

    field :add_recent_item, mutation: Mutations::AddRecentItem
    field :clear_recent_items, mutation: Mutations::ClearRecentItems
    field :submit_form, mutation: Mutations::SubmitForm

    field :clear_mci, mutation: Mutations::AcHmis::ClearMci
  end
end
