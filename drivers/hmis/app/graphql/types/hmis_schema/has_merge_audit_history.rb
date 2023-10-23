###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasMergeAuditHistory
      extend ActiveSupport::Concern

      class_methods do
        def merge_audit_history_field(
          name = :merge_audit_history,
          description = nil,
          **override_options,
          &block
        )
          default_field_options = {
            type: Types::HmisSchema::MergeAuditEvent.page_type,
            null: false,
            description: description,
          }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            resolve_merge_audit_history(object)
          end

          define_method(:merge_audit_history) do
            return Hmis::ClientMergeAudit.none unless current_user.can_merge_clients?

            object.merge_audits.order(:merged_at)
          end
        end
      end
    end
  end
end
