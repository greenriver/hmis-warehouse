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
          association_name: :custom_data_elements,
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
            custom_data_elements = load_ar_association(object, association_name)

            # Group together elements of the same type so they can be resolved as an array
            custom_data_elements.preload(:data_element_definition).
              group_by(&:data_element_definition_id).
              values.
              map do |values|
                definition = values.first.data_element_definition
                # This will be resolved as a HmisSchema::CustomDataElement
                OpenStruct.new(
                  id: definition.id,
                  key: definition.key,
                  label: definition.label,
                  repeats: definition.repeats,
                  values: values,
                )
              end
          end
        end
      end
    end
  end
end
