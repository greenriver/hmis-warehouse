###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
          default_field_options = { type: HmisSchema::File.page_type, null: false, description: description }
          field_options = default_field_options.merge(override_options)
          field(name, **field_options) do
            argument :sort_order, Types::HmisSchema::FileSortOption, required: false
            instance_eval(&block) if block_given?
          end
        end
      end

      def resolve_files_with_loader(association_name = :files, **args)
        load_ar_association(object, association_name, scope: scoped_files(Hmis::File, **args))
      end

      def resolve_files(scope = object.files, **args)
        scoped_files(scope, **args)
      end

      private

      def scoped_files(scope, sort_order: :date_created)
        scope = scope.viewable_by(current_user)
        scope = scope.sort_by_option(sort_order) if sort_order.present?
        scope
      end
    end
  end
end
