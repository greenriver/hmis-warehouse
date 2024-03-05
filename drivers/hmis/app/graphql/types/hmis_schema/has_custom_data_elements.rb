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
            # This association, defined in `Hmis::Hud::Concerns::HasCustomDataElements`,
            # is a has_many through the custom_data_elements relation. That means it will
            # only load the CustomDataElementDefinitions for which this record has a value.
            #
            # TODO CHECK: is this N+1 because of the `distinct` scope on the association?
            load_ar_association(object, :custom_data_element_definitions)
          end
        end
      end
    end
  end
end
