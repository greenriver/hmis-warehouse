###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasFunders
      extend ActiveSupport::Concern

      class_methods do
        def funders_field(name = :funders, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::Funder.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::FunderSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_funders_with_loader(association_name = :funders, **args)
        load_ar_association(object, association_name, scope: scoped_funders(Hmis::Hud::Funder, **args))
      end

      def resolve_funders(scope = object.funders, **args)
        scoped_funders(scope, **args)
      end

      private

      def scoped_funders(scope, sort_order: nil)
        scope = scope.viewable_by(current_user)
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
