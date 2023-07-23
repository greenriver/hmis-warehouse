###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasEmploymentEducations
      extend ActiveSupport::Concern

      class_methods do
        def employment_educations_field(name = :employment_educations, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::EmploymentEducation.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            instance_eval(&block) if block_given?
          end

          define_method(name) do
            resolve_employment_educations
          end
        end
      end

      def resolve_employment_educations(scope = object.employment_educations, **args)
        scoped_employment_educations(scope, **args)
      end

      private

      def scoped_employment_educations(scope)
        scope.viewable_by(current_user).order(information_date: :desc)
      end
    end
  end
end
