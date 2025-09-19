# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  # Custom base field class that provides common functionality for all fields in the schema.
  # This includes:
  # - A consistent authorization layer (`permissions` or `authorize_with`)
  # - Automatic pagination for fields that return a paginated type
  # - Support for default values
  class BaseField < GraphQL::Schema::Field
    argument_class Types::BaseArgument

    # @param default_value [Object] A default value for the field if it resolves to nil.
    # @param permissions [Symbol, Array<Symbol>] (Deprecated) The required permission(s) to view the field. Mutually exclusive with `authorize_with`.
    # @param authorize_with [Proc] A lambda for custom authorization logic. It receives `user` and `object` and should return a boolean. Mutually exclusive with `permissions`.
    def initialize(*args, default_value: nil, permissions: nil, authorize_with: nil, **kwargs, &block)
      raise ArgumentError "don't use permissions and authorize_with" if permissions && authorize_with

      @permissions = Array.wrap(permissions)
      @authorize_with = authorize_with

      after_paginate = kwargs.delete(:after_paginate)
      nodes_count_proc = kwargs.delete(:nodes_count)
      super(*args, **kwargs, &block)

      extension(DefaultValueExtension, default_value: default_value) if default_value

      return_type = kwargs[:type]
      return unless return_type.is_a?(Class) && return_type < BasePaginated

      # ArrayPaginated is an empty class inheriting from BasePaginated
      if return_type < ArrayPaginated
        extension(PaginationWrapperExtension, is_array: true, after_paginate: after_paginate)
      else
        extension(PaginationWrapperExtension, after_paginate: after_paginate, nodes_count_proc: nodes_count_proc)
      end
    end

    # Field-level authorization
    # https://graphql-ruby.org/authorization/authorization.html#field-authorization
    def authorized?(object, args, ctx)
      return false unless super(object, args, ctx)

      if @permissions.any?
        # if `permissions:` was given, then require the current user to have the specified permissions on the object
        @permissions.all? do |perm|
          GraphqlPermissionChecker.current_permission_for_context?(ctx, permission: perm, entity: object)
        end
      elsif @authorize_with
        @authorize_with.call(ctx[:current_user], object)
      else
        true
      end
    end

    def filters_argument(node_class, arg_name = :filters, type_name: nil, omit: [], **kwargs)
      argument(arg_name, node_class.filter_options_type(type_name, omit: omit), required: false, **kwargs)
    end

    class PaginationWrapperExtension < GraphQL::Schema::FieldExtension
      def apply
        field.argument(:offset, Integer, required: false)
        field.argument(:limit, Integer, required: false)
      end

      def resolve(object:, arguments:, context:, **_rest)
        cleaned_arguments = arguments.dup

        pagination_arguments = {}

        [:offset, :limit].each do |arg|
          value = cleaned_arguments.delete(arg)
          pagination_arguments[arg] = value if value.present?
        end

        resolved_object = yield(object, cleaned_arguments)

        if options[:is_array]
          result = Types::PaginatedArray.new(resolved_object, **pagination_arguments)
        else
          result = Types::PaginatedScope.new(resolved_object, **pagination_arguments, nodes_count_proc: options[:nodes_count_proc])
        end
        options[:after_paginate]&.call(result.nodes&.to_a, context)
        result
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
