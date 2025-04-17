###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralParticipant < Types::BaseObject
    # object is a Hmis::Ce::ReferralParticipant

    field :id, ID, null: false
    field :swimlane, HmisSchema::CeSwimlane, null: false
    field :user, Application::User, null: false

    def swimlane
      load_ar_association(object, :swimlane)
    end

    def user
      load_ar_association(object, :user)
    end
  end
end
