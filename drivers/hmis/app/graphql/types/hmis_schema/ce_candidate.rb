###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeCandidate < Types::BaseObject
    field :id, ID, null: false
    # TODO - do we want to expose client here? Maybe we can show candidates without revealing PII
    field :client, HmisSchema::Client, null: false
    field :priority_score, Integer, null: false
  end
end
