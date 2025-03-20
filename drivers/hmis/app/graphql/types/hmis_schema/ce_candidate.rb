###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeCandidate < Types::BaseObject
    field :id, ID, null: false
    field :client_id, ID, null: false
    field :client, HmisSchema::Client, null: true
    field :priority_score, Integer, null: false

    def client
      load_ar_association(object, :client, scope: Hmis::Hud::Client.viewable_by(current_user))
    end
  end
end
