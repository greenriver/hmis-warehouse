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
  end
end
