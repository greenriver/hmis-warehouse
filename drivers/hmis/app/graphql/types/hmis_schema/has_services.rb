###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasServices
      extend ActiveSupport::Concern

      class_methods do
        def services_field(name = :services, description = nil, filter_args: {}, **override_options, &block)
          default_field_options = { type: HmisSchema::Service.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::ServiceSortOption, required: false
            argument :service_type, GraphQL::Types::ID, required: false
            argument :service_category, GraphQL::Types::ID, required: false
            argument :search_term, String, required: false
            filters_argument HmisSchema::Service, **filter_args
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_services_with_loader(association_name = :hmis_services, **args)
        load_ar_association(object, association_name, scope: scoped_services(Hmis::Hud::HmisService, **args))
      end

      def resolve_services(scope = object.hmis_services, **args)
        scoped_services(scope, **args)
      end

      private

      def scoped_services(scope, sort_order: :date_provided, service_type: nil, service_category: nil, search_term: nil, filters: nil)
        scope = scope.viewable_by(current_user)
        scope = scope.apply_filters(filters) if filters.present?
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope = scope.where(service_type: service_type) if service_type.present?
        scope = scope.in_service_category(service_category) if service_category.present?
        scope = scope.matching_search_term(search_term) if search_term.present?
        scope
      end
    end
  end
end
