###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseField < GraphQL::Schema::Field
    argument_class Types::BaseArgument

    def initialize(**kwargs, &block)
      super
      return_type = kwargs[:type]
      return unless return_type.is_a?(Class) && return_type < BasePaginated

      extension(PaginationWrapperExtension)
    end

    class PaginationWrapperExtension < GraphQL::Schema::FieldExtension
      def apply
        field.argument(:offset, Integer, required: false)
        field.argument(:limit, Integer, required: false)
      end

      def resolve(object:, arguments:, **_rest)
        cleaned_arguments = arguments.dup

        pagination_arguments = {}

        [:offset, :limit].each do |arg|
          value = cleaned_arguments.delete(arg)
          pagination_arguments[arg] = value if value.present?
        end

        resolved_object = yield(object, cleaned_arguments)
        Types::PaginatedScope.new(resolved_object, **pagination_arguments)
      end
    end
  end
end
