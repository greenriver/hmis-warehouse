###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::HouseholdClient < Types::BaseObject
    description 'HUD Client within a Household'
    field :id, ID, null: false
    field :relationship_to_ho_h, HmisSchema::Enums::RelationshipToHoH, null: false
    field :client, HmisSchema::Client, null: false
    field :enrollment, HmisSchema::Enrollment, null: false

    # object is hash with the format { relationship_to_ho_h: String, client: Client, enrollment: Enrollment }

    def id
      "#{object[:enrollment].id}:#{object[:client].id}"
    end
  end
end
