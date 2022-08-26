###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Household < Types::BaseObject
    description 'HUD Household'
    field :id, ID, null: false
    field :household_clients, [HmisSchema::HouseholdClient], null: false

    # object is a scope on Hmis::Hud::Enrollment

    def id
      object.first.household_id
    end

    def household_clients
      object.map do |enrollment|
        {
          relationship_to_ho_h: enrollment.relationship_to_ho_h,
          client: enrollment.client,
          enrollment: enrollment,
        }
      end
    end
  end
end
