###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasInventories
      extend ActiveSupport::Concern

      class_methods do
        def inventories_field(name = :inventories, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::Inventory.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::InventorySortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_inventories_with_loader(association_name = :inventories, **args)
        load_ar_association(object, association_name, scope: apply_inventory_arguments(Hmis::Hud::Inventory, **args))
      end

      def resolve_inventories(scope = object.inventories, **args)
        apply_inventory_arguments(scope, **args)
      end

      private

      def apply_inventory_arguments(scope, sort_order: nil)
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
