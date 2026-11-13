###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  module HmisSchema
    module HasFiles
      extend ActiveSupport::Concern

      class_methods do
        def files_field(name = :files, description = nil, **override_options, &block)
          default_field_options = {
            type: HmisSchema::File.page_type,
            null: false,
            description: description,
            after_paginate: ->(nodes, ctx) {
              # Preload dependencies for HmisFilePolicy, which checks project permissions for
              # enrollment files and client permissions for client files.
              policy_context = ctx[:current_user].policy_context
              policy_context.preload_project_dependencies(nodes.filter_map { |file| file.enrollment&.project_pk })
              policy_context.preload_client_dependencies(nodes.map(&:client_id))
            },
          }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::FileSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_files(scope = object.files, **args)
        scoped_files(scope, **args)
      end

      private

      def scoped_files(scope, sort_order: :date_created, client_ids: nil)
        # Passing client IDs to the viewable_by scope improves performance
        scope = scope.viewable_by(current_user, client_ids: client_ids)
        # HmisFilePolicy reads file.enrollment directly, so preload it to avoid an N+1 on policy checks
        scope = scope.preload(:enrollment)
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
