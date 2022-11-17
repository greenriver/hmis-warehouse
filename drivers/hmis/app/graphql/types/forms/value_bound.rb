###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::ValueBound < Types::BaseObject
    description 'Bound for the response value. The bound may or may not be dependent on another questions answer.'

    field :type, Forms::Enums::BoundType, null: false
    field :value_number, Integer, null: true
    field :value_date, GraphQL::Types::ISO8601Date, null: true
    field :question, String, 'Link ID of dependent question, if bound value should be equal to the questions answer', null: true
  end
end
