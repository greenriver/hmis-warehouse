###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasAuditHistory
      extend ActiveSupport::Concern

      class_methods do
        def audit_history_field(name = :audit_history, description = nil, field_permissions: {}, transform_changes: nil, **override_options, &block)
          default_field_options = {
            type: audit_event_type(field_permissions: field_permissions, transform_changes: transform_changes).page_type,
            null: false,
            description: description,
          }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            resolve_audit_history
          end

          # Override "resolve_audit_history" to override default scope behavior
          define_method(:resolve_audit_history) do
            address_ids = object.addresses.with_deleted.pluck(:id)
            name_ids = object.names.with_deleted.pluck(:id)
            contact_ids = object.contact_points.with_deleted.pluck(:id)

            v_t = GrPaperTrail::Version.arel_table
            client_changes = v_t[:item_id].eq(object.id).and(v_t[:item_type].in(['Hmis::Hud::Client', 'GrdaWarehouse::Hud::Client']))
            address_changes = v_t[:item_id].in(address_ids).and(v_t[:item_type].eq('Hmis::Hud::CustomClientAddress'))
            name_changes = v_t[:item_id].in(name_ids).and(v_t[:item_type].eq('Hmis::Hud::CustomClientName'))
            contact_changes = v_t[:item_id].in(contact_ids).and(v_t[:item_type].eq('Hmis::Hud::CustomClientContactPoint'))

            GrPaperTrail::Version.where(client_changes.or(address_changes).or(name_changes).or(contact_changes)).
              where.not(object_changes: nil, event: 'update').
              unscope(:order). # Unscope to remove default order, otherwise it will conflict
              order(created_at: :desc)
          end
        end
      end
    end
  end
end
