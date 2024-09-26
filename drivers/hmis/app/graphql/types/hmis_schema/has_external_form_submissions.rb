###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  module HmisSchema
    module HasExternalFormSubmissions
      extend ActiveSupport::Concern

      class_methods do
        def external_form_submissions_field(name = :external_form_submissions, description = nil, filter_args: {}, **override_options, &block)
          default_field_options = { type: HmisSchema::ExternalFormSubmission.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            filters_argument HmisSchema::ExternalFormSubmission, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_external_form_submissions(scope = object.external_form_submissions, filters: nil)
        return scope.none unless current_permission?(permission: :can_manage_external_form_submissions, entity: object)

        scope = scope.apply_filters(filters)
        scope.order(submitted_at: :desc, id: :desc)
      end
    end
  end
end
