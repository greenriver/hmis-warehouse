###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Application::ActivityLogRecord < Types::BaseObject
    graphql_name 'ActivityLogRecord'

    field :record_type, String, null: false
    field :record_id, String, null: false
  end
end
