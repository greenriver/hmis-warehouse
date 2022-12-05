###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasHealthAndDvs
      extend ActiveSupport::Concern

      class_methods do
        def health_and_dvs_field(name = :events, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::HealthAndDv.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_health_and_dvs(scope = object.health_and_dvs, **args)
        scoped_health_and_dvs(scope, **args)
      end

      private

      def scoped_health_and_dvs(scope)
        scope.viewable_by(current_user)
      end
    end
  end
end
