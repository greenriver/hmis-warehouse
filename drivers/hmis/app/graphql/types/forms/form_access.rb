###
# Copyright Green River Data Group, Inc.
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
          define_method(:policy) { @policy ||= policy_for(object, policy_type: :form_definition) }

          bool_field(:can_manage_form) { policy.can_manage_form? }
          bool_field(:can_duplicate_form) { policy.can_duplicate? }
          bool_field(:can_publish_form) { policy.can_publish? }
        end
      end
    end
  end
end
