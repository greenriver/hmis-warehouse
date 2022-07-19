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
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_organizations(scope = object.organizations, user: current_user)
        organizations_scope = scope.viewable_by(user)
        organizations_scope
      end
    end
  end
end
