###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasFormDefinitionId
      extend ActiveSupport::Concern

      included do
        field :form_definition_id, GraphQL::Types::ID, null: true

        define_method(:form_definition_id) do
          load_ar_association(object, :form_processor)&.definition_id
        end
      end
    end
  end
end
