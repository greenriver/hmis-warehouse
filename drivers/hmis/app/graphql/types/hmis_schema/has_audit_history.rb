###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasAuditHistory
      extend ActiveSupport::Concern

      class_methods do
        def audit_history_field(
          name = :audit_history,
          description = nil,
          association_name: :versions,
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
            resolve_audit_history
          end

          # Override "resolve_audit_history" to override default scope behavior
          define_method(:resolve_audit_history) do
            # Unscope to remove default order, otherwise it will conflict
            object.send(association_name).where.not(object_changes: nil, event: 'update').unscope(:order).order(created_at: :desc)
          end
        end
      end
    end
  end
end
