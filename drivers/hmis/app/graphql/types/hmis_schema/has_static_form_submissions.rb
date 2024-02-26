###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasStaticFormSubmissions
      extend ActiveSupport::Concern

      class_methods do
        def static_form_submissions_field(name = :static_form_submissions, description = nil, filter_args: {}, **override_options, &block)
          default_field_options = { type: HmisSchema::StaticFormSubmission.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            filters_argument HmisSchema::StaticFormSubmission, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_static_form_submissions(scope = object.static_form_submissions, filters: nil)
        scope.order(submitted_at: :desc, :id)
        raise 'testing'
      end
    end
  end
end
