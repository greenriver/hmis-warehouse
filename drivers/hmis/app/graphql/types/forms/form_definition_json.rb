###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::FormDefinitionJson < Types::BaseObject
    field :item, [Types::Forms::FormItem], 'Nested items', null: false
  end
end
