###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasYouthEducationStatuses
      extend ActiveSupport::Concern

      class_methods do
        def youth_education_statuses_field(name = :youth_education_statuses, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::YouthEducationStatus.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            resolve_youth_education_statuses
          end
        end
      end

      def resolve_youth_education_statuses(scope = object.youth_education_statuses, **args)
        scoped_youth_education_statuses(scope, **args)
      end

      private

      def scoped_youth_education_statuses(scope)
        scope.viewable_by(current_user).order(information_date: :desc)
      end
    end
  end
end
