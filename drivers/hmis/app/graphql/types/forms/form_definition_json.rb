###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::FormDefinitionJson < Types::BaseObject
    skip_activity_log
    field :item, [Types::Forms::FormItem], 'Nested items', null: false
  end
end
