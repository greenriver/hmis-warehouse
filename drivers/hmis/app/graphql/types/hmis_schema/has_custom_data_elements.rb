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
            resolve_custom_data_elements(object)
          end

          # FIXME can we use data loader to load the CDEDs? they only have a relationship via owner_type
          define_method(:resolve_custom_data_elements) do |record, definition_scope: nil|
            # Always resolve all _available_ custom element types for this record type,
            # even if they have no value, so that they can be shown as empty if missing.
            definition_scope ||= Hmis::Hud::CustomDataElementDefinition.for_type(record.class.sti_name)
            return [] unless definition_scope.exists?

            definition_scope

            # custom_values = Hmis::Hud::CustomDataElement.where(owner: record).group_by(&:data_element_definition_id)
            # # Group together elements of the same type so they can be resolved as an array
            # definition_scope.map do |definition|
            #   # This will be resolved as a HmisSchema::CustomDataElement
            #   OpenStruct.new(
            #     id: "#{record.id}:#{definition.id}",
            #     values: custom_values[definition.id],
            #     **definition.slice(:key, :label, :repeats, :at_occurrence),
            #   )
            # end
          end
        end
      end
    end
  end
end
