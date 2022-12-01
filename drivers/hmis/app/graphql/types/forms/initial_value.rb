###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::InitialValue < Types::BaseObject
    description 'Initial value when item is first rendered'

    field :value_code, String, 'If question is choice type, initial value', null: true
    field :value_number, Integer, 'If question is numeric, initial value', null: true
    field :value_boolean, Boolean, 'If question is boolean type, initial value', null: true
    field :value_local_constant, String, 'Name of local variable to use as initial value if present. Variable type should match item type.', null: true

    # Add date, datetime, etc as needed
  end
end
