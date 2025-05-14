###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeCandidate < Types::BaseObject
    # object is a Hmis::Ce::Match
    field :id, ID, null: false
    field :client_id, ID, null: false
    field :client, HmisSchema::Client, null: true, description: 'Null if the user lacks permission to view the client'
    field :priority_score, Integer, null: false

    def client
      load_ar_scope(scope: Hmis::Hud::Client.viewable_by(current_user), id: object.client_id)
    end
  end
end
