###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::HouseholdClient < Types::BaseObject
    description 'HUD Client within a Household'
    field :id, ID, null: false
    field :relationship_to_ho_h, Types::HmisSchema::Enums::Hud::RelationshipToHoH, null: false, default_value: 99
    field :client, HmisSchema::Client, null: false
    field :enrollment, HmisSchema::Enrollment, null: false

    # object is hash with the format { relationship_to_ho_h: String, client: Client, enrollment: Enrollment }

    def id
      "#{enrollment.id}:#{client.id}"
    end
    alias activity_log_object_identity id

    def client
      load_ar_association(enrollment, :client)
    end

    def enrollment
      object.fetch(:enrollment)
    end
  end
end
