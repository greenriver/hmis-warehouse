###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module Forms
    module FormAccess
      extend ActiveSupport::Concern

      included do
        access_field do
          field :can_manage_form, GraphQL::Types::Boolean, null: false
          field :can_duplicate_form, GraphQL::Types::Boolean, null: false
          field :can_publish_form, GraphQL::Types::Boolean, null: false

          define_method(:can_manage_form) do
            policy_for(object, policy_type: :form_definition).can_manage_form?
          end

          define_method(:can_duplicate_form) do
            policy_for(object, policy_type: :form_definition).can_duplicate?
          end

          define_method(:can_publish_form) do
            policy_for(object, policy_type: :form_definition).can_publish?
          end
        end
      end
    end
  end
end
