###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasAuditHistory
      extend ActiveSupport::Concern

      class_methods do
        # Declares a paginated audit-history field. The including type must define the resolver, and
        # it must start by denying access unless its own `can_audit?` policy check passes. Audit
        # history reports raw before/after values for every audited column; permission to view a
        # record does not imply permission to audit it.
        def audit_history_field(
          name = :audit_history,
          description = nil,
          excluded_keys: nil,
          transform_changes: nil,
          filter_args: {},
          **override_options,
          &block
        )
          default_field_options = {
            type: audit_event_type(excluded_keys: excluded_keys, transform_changes: transform_changes).page_type,
            null: false,
            description: description,
          }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            filters_argument BaseAuditEvent, **filter_args
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            raise 'must be implemented by the including type, with a can_audit? policy check'
          end
        end
      end
    end
  end
end
