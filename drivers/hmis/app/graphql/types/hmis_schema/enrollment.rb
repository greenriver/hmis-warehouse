###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enrollment < Types::BaseObject
    description 'HUD Enrollment'
    field :id, ID, null: false
    field :project, Types::HmisSchema::Project, null: false
    field :entry_date, GraphQL::Types::ISO8601DateTime, null: true
    field :exit_date, GraphQL::Types::ISO8601DateTime, null: true
  end
end
