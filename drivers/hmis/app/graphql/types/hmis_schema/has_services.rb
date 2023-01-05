###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasServices
      extend ActiveSupport::Concern

      class_methods do
        def services_field(name = :services, description = nil, **override_options, &block)
          default_field_options = { type: HmisSchema::Service.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::ServiceSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_services_with_loader(association_name = :services, **args)
        load_ar_association(object, association_name, scope: scoped_services(Hmis::Hud::Service, **args))
      end

      def resolve_services(scope = object.services, **args)
        scoped_services(scope, **args)
      end

      private

      def scoped_services(scope, sort_order: :date_provided)
        scope = scope.viewable_by(current_user)
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
