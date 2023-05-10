###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCustomDataElements
      extend ActiveSupport::Concern

      class_methods do
        def custom_data_elements_field(
          name = :custom_data_elements,
          description = nil,
          **override_options,
          &block
        )
          default_field_options = {
            type: [Types::HmisSchema::CustomDataElement],
            null: false,
            description: description,
          }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            resolve_custom_data_elements
          end

          define_method(:resolve_custom_data_elements) do
            # Always resolve all _available_ custom element types for this record type,
            # even if they have no value, so that they can be shown as empty if missing.
            definitions = Hmis::Hud::CustomDataElementDefinition.where(owner_type: object.class.name)
            return unless definitions.exists?

            custom_values = Hmis::Hud::CustomDataElement.where(owner: object).group_by(&:data_element_definition_id)
            # Group together elements of the same type so they can be resolved as an array
            definitions.map do |definition|
              # This will be resolved as a HmisSchema::CustomDataElement
              OpenStruct.new(
                id: definition.id,
                key: definition.key,
                label: definition.label,
                repeats: definition.repeats,
                values: custom_values[definition.id],
              )
            end
          end
        end
      end
    end
  end
end
