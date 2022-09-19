###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::MutationType < Types::BaseObject
    field :create_client, mutation: Mutations::CreateClient
    field :create_enrollment, mutation: Mutations::CreateEnrollment
    field :add_household_members_to_enrollment, mutation: Mutations::AddHouseholdMembersToEnrollment
    field :set_ho_h_for_enrollment, mutation: Mutations::SetHoHForEnrollment
    field :update_enrollment, mutation: Mutations::UpdateEnrollment
    field :delete_enrollment, mutation: Mutations::DeleteEnrollment
    field :create_organization, mutation: Mutations::CreateOrganization
    field :update_organization, mutation: Mutations::UpdateOrganization
  end
end
