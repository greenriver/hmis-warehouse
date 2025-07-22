# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseField < GraphQL::Schema::Field
    argument_class Types::BaseArgument

    def initialize(*args, default_value: nil, permissions: nil, policy_name: nil, policy_action: nil, **kwargs, &block)
      @permissions = Array.wrap(permissions)
      @policy_name = policy_name
      @policy_action = policy_action&.to_sym

      # Validate that policy parameters are used together
      if (@policy_name.present? && @policy_action.blank?) || (@policy_name.blank? && @policy_action.present?) # rubocop:disable Style/IfUnlessModifier
        raise ArgumentError, 'policy_name and policy_action must be provided together'
      end

      after_paginate = kwargs.delete(:after_paginate)
      super(*args, **kwargs, &block)

      extension(DefaultValueExtension, default_value: default_value) if default_value

      return_type = kwargs[:type]
      return unless return_type.is_a?(Class) && return_type < BasePaginated

      # ArrayPaginated is an empty class inheriting from BasePaginated
      if return_type < ArrayPaginated
        extension(PaginationWrapperExtension, is_array: true, after_paginate: after_paginate)
      else
        extension(PaginationWrapperExtension, after_paginate: after_paginate)
      end
    end

    # Field-level authorization
    # https://graphql-ruby.org/authorization/authorization.html#field-authorization
    def authorized?(object, args, ctx)
      base_authorized = super(object, args, ctx)
      if @permissions.any?
        # if `permissions:` was given, then require the current user to have the specified permissions on the object
        base_authorized && @permissions.all? do |perm|
          GraphqlPermissionChecker.current_permission_for_context?(ctx, permission: perm, entity: object)
        end
      elsif @policy_name
        # if `policy_name:` and `policy_action:` were given, require the user to be able to perform that action on that policy
        current_user = ctx[:current_user]
        policy = current_user.policy_for(object, policy_type: @policy_name)

        raise ArgumentError, "Policy #{policy.class.name} does not respond to #{@policy_action}" unless @policy_action && policy.respond_to?(@policy_action)

        base_authorized && policy.send(@policy_action)
      else
        base_authorized
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
          result = Types::PaginatedScope.new(resolved_object, **pagination_arguments)
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
