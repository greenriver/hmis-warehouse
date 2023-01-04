###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::MutationType < Types::BaseObject
    field :create_client, mutation: Mutations::CreateClient
    field :update_client, mutation: Mutations::UpdateClient
    field :update_client_image, mutation: Mutations::UpdateClientImage
    field :create_enrollment, mutation: Mutations::CreateEnrollment
    field :add_household_members_to_enrollment, mutation: Mutations::AddHouseholdMembersToEnrollment
    field :set_ho_h_for_enrollment, mutation: Mutations::SetHoHForEnrollment
    field :update_enrollment, mutation: Mutations::UpdateEnrollment
    field :delete_enrollment, mutation: Mutations::DeleteEnrollment
    field :create_organization, mutation: Mutations::CreateOrganization
    field :update_organization, mutation: Mutations::UpdateOrganization
    field :delete_organization, mutation: Mutations::DeleteOrganization
    field :create_project, mutation: Mutations::CreateProject
    field :update_project, mutation: Mutations::UpdateProject
    field :delete_project, mutation: Mutations::DeleteProject
    field :create_project_coc, mutation: Mutations::CreateProjectCoc
    field :update_project_coc, mutation: Mutations::UpdateProjectCoc
    field :delete_project_coc, mutation: Mutations::DeleteProjectCoc
    field :create_funder, mutation: Mutations::CreateFunder
    field :update_funder, mutation: Mutations::UpdateFunder
    field :delete_funder, mutation: Mutations::DeleteFunder
    field :create_inventory, mutation: Mutations::CreateInventory

    field :create_units, mutation: Mutations::CreateUnits
    field :create_beds, mutation: Mutations::CreateBeds
    # field :update_unit, mutation: Mutations::UpdateUnit
    # field :update_bed, mutation: Mutations::UpdateBed
    # field :delete_units, mutation: Mutations::DeleteUnits
    # field :delete_beds, mutation: Mutations::DeleteBeds

    field :update_inventory, mutation: Mutations::UpdateInventory
    field :delete_inventory, mutation: Mutations::DeleteInventory
    field :create_service, mutation: Mutations::CreateService
    field :update_service, mutation: Mutations::UpdateService
    field :delete_service, mutation: Mutations::DeleteService
    field :save_assessment, mutation: Mutations::SaveAssessment
    field :submit_assessment, mutation: Mutations::SubmitAssessment
    field :create_direct_upload, mutation: Mutations::CreateDirectUpload
  end
end
