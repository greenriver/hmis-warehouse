###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::InitialValue < Types::BaseObject
    description 'Initial value when item is first rendered'

    field :initial_behavior, Types::Forms::Enums::InitialBehavior, null: false

    field :value_local_constant, String, 'Name of local variable to use as initial value if present. Variable type should match item type.', null: true
    field :value_code, String, 'Code to set as initial value', null: true
    field :value_number, Integer, 'Number to set as initial value', null: true
    field :value_boolean, Boolean, 'Boolean to set as initial value', null: true
  end
end
