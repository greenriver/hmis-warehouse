###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Types::DateRange < Types::BaseObject
  skip_activity_log

  field :start_date, GraphQL::Types::ISO8601Date, null: false
  field :end_date, GraphQL::Types::ISO8601Date, null: false
end
