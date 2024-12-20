###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeOpportunity < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :status, String, null: false
  end
end
