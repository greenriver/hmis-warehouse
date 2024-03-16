###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
            resolve_custom_data_elements(object)
          end
        end
      end

      def resolve_custom_data_elements(record)
        # Load all CustomDataElement values for this record
        cde_values = load_ar_association(record, :custom_data_elements).group_by(&:data_element_definition_id)

        # Load all CustomDataElementDefinitions that have values for this record
        cde_definitions = load_ar_association(record, :custom_data_element_definitions)

        # Array of relevant CustomDataElementDefinitions, with value(s)
        cde_definitions.uniq.map do |cded|
          Hmis::Hud::GraphqlCdeValueAdapter.new(
            definition: cded,
            custom_data_elements: cde_values[cded.id] || [],
          )
        end
      end
    end
  end
end
