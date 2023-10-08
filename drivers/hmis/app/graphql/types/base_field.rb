###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseField < GraphQL::Schema::Field
    argument_class Types::BaseArgument

    def initialize(*args, default_value: nil, **kwargs, &block)
      super(*args, **kwargs, &block)

      extension(DefaultValueExtension, default_value: default_value) if default_value.present?

      return_type = kwargs[:type]
      return unless return_type.is_a?(Class) && return_type < BasePaginated

      extension(PaginationWrapperExtension)
    end

    def filters_argument(node_class, arg_name = :filters, type_name: nil, omit: [], **kwargs)
      argument(arg_name, node_class.filter_options_type(type_name, omit: omit), required: false, **kwargs)
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

    # Support setting a default value for a field
    # Credit:  https://github.com/rmosolgo/graphql-ruby/issues/2783#issuecomment-592960093
    class DefaultValueExtension < GraphQL::Schema::FieldExtension
      def after_resolve(value:, **_rest)
        if value.nil?
          options[:default_value]
        else
          value
        end
      end
    end
  end
end
