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
          default_field_options = { type: [HmisSchema::Bed], null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_beds(scope = object.beds)
        scope
      end
    end
  end
end
