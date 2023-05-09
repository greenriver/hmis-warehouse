###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Household < Types::BaseObject
    description 'HUD Household'
    field :id, ID, null: false
    field :short_id, ID, null: false
    field :household_clients, [HmisSchema::HouseholdClient], null: false
    field :household_size, Int, null: false

    # object is a Hmis::Hud::Household

    def short_id
      object.enrollments.first.short_household_id.upcase
    end

    def household_clients
      object.enrollments.map do |enrollment|
        {
          relationship_to_ho_h: enrollment.relationship_to_ho_h,
          client: enrollment.client,
          enrollment: enrollment,
        }
      end
    end
  end
end
