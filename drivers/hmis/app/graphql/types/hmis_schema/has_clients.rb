###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasClients
      extend ActiveSupport::Concern

      class_methods do
        def clients_field(name = :clients, description = nil, type: [Types::HmisSchema::Client], **override_options, &block)
          default_field_options = { type: type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::ClientSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_clients(scope = object.clients, sort_order: :last_name_asc, _user: current_user, no_sort: false)
        clients_scope = scope
        clients_scope = clients_scope.sort_by_option(sort_order) unless no_sort
        clients_scope
      end
    end
  end
end
