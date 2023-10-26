###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  module HmisSchema
    module HasApplicationUsers
      extend ActiveSupport::Concern

      class_methods do
        def application_users_field(name = :services, description = nil, filter_args: {}, **override_options, &block)
          default_field_options = { type: Application::User.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            filters_argument Application::User, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_application_users(scope, filters: nil)
        scope = scope.viewable_by(current_user)
        scope = scope.apply_filters(filters) if filters.present?
        scope
      end
    end
  end
end
