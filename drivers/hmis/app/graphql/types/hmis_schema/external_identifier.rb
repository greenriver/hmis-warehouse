###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ExternalIdentifier < Types::BaseObject
    description 'External Identifier'
    field :id, ID, 'API ID, not the actual identifier value', null: false
    field :identifier, ID, 'The identifier value', null: true
    field :url, String, null: true
    field :label, String, null: false

    # Object is a hash with keys matching the field names
  end
end
