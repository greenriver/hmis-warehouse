###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasBeds
      extend ActiveSupport::Concern

      class_methods do
        def beds_field(name = :beds, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::Bed.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :bed_type, HmisSchema::Enums::InventoryBedType, required: false
            argument :active, GraphQL::Types::Boolean, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_beds(scope = object.beds, bed_type: nil, active: nil)
        scope = scope.order(created_at: :desc)
        scope = scope.where(bed_type: bed_type) if bed_type.present?
        if active == true
          scope.active
        elsif active == false
          scope.inactive
        else
          scope
        end
      end
    end
  end
end
