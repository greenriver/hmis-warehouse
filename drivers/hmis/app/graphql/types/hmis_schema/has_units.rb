###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasUnits
      extend ActiveSupport::Concern

      class_methods do
        def units_field(name = :units, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::Unit.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :active, GraphQL::Types::Boolean, required: false
            argument :occupied, GraphQL::Types::Boolean, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_units(scope = object.units, active: nil, occupied: nil)
        scope = scope.order(created_at: :desc, name: :asc)
        scope = scope.active if active == true
        scope = scope.inactive if active == false
        scope = scope.occupied_on(Date.current) if occupied
        scope
      end
    end
  end
end
