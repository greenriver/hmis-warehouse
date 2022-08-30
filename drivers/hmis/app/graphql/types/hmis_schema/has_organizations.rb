###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasOrganizations
      extend ActiveSupport::Concern

      class_methods do
        def organizations_field(name = :organizations, description = nil, **override_options, &block)
          default_field_options = { type: [Types::HmisSchema::Organization], null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::OrganizationSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_organizations_with_loader(association_name = :organizations, **args)
        load_ar_association(object, association_name, scope: apply_organization_arguments(Hmis::Hud::Organization, **args))
      end

      def resolve_organizations(scope = object.organizations, **args)
        apply_organization_arguments(scope, **args)
      end

      private

      def apply_organization_arguments(scope, user: current_user, sort_order: nil)
        organizations_scope = scope.viewable_by(user)
        organizations_scope.sort_by_option(sort_order) if sort_order.present?
      end
    end
  end
end
