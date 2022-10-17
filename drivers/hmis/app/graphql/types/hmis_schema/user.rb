###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::User < Types::BaseObject
    description 'HUD User'
    field :id, ID, null: false
    field :name, String, null: false
  end
end
