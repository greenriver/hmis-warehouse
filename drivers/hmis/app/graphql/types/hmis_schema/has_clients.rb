###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasClients
      extend ActiveSupport::Concern

      class_methods do
        def clients_field(name = :clients, description = nil, type: Types::HmisSchema::Client.page_type, **override_options, &block)
          default_field_options = { type: type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::ClientSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_clients_with_loader(association_name = :clients, **args)
        load_ar_association(object, association_name, scope: scoped_clients(Hmis::Hud::Client, **args))
      end

      def resolve_clients(scope = object.clients, **args)
        scoped_clients(scope, **args)
      end

      private

      def scoped_clients(scope, sort_order: :last_name_a_to_z, no_sort: false, _user: current_user)
        # The visible_to scope is already applied when we get here in every case so far
        # scope = scope.visible_to(user)
        scope = scope.sort_by_option(sort_order) unless no_sort
        scope
      end
    end
  end
end
