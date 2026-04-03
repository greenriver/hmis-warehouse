###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class BaseAccess < BaseObject
    class_attribute :default_policy_type

    def self.build(node_class, class_name: nil, policy_type: nil, &block)
      Class.new(self) do
        skip_activity_log
        graphql_name(class_name || "#{node_class.graphql_name}Access")
        self.default_policy_type = policy_type # default policy type for the class, can be overridden for individual fields
        instance_eval(&block) if block

        field :id, ID, null: false

        def id
          [object.respond_to?(:id) ? object.id : nil, current_user&.id].compact.first
        end
      end
    end

    # Legacy: exposes a raw user-level permission flag. Prefer {#policy_field} / {#global_policy_field} (policies).
    # Note: this is not compatible with multi-HMIS because it reflects truly global permission rather than data-source permission.
    def self.root_can(permission, **field_attrs)
      field permission, Boolean, null: false, **field_attrs
      define_method(permission) do
        current_user.send(permission) || false
      end
    end

    # Legacy: combines raw user-level permissions. Prefer policy predicates. Phasing out in favor of {#policy_field}.
    def self.root_can_composite(name, permissions:, mode:, **field_attrs)
      field name, Boolean, null: false, **field_attrs

      raise 'unrecognized permission mode' unless [:any, :all].include?(mode)

      define_method(name) do
        current_user.permissions?(*permissions, mode: mode)
      end
    end

    # Legacy: resolves a single raw permission on `object` via {GraphqlPermissionChecker}. Prefer {#policy_field}.
    #
    # @param permission [Symbol] suffix after `can_` (e.g. `:view_partial_ssn` → permission `can_view_partial_ssn`)
    # @param field_name [Symbol] optional GraphQL name (default `can_<permission>`)
    def self.can(permission, field_name: nil, **field_attrs)
      field_name ||= "can_#{permission}"

      field field_name, Boolean, null: false, **field_attrs

      define_method(field_name) do
        current_permission?(permission: :"can_#{permission}", entity: object)
      end
    end

    # Legacy: OR/AND of raw permissions on `object`. Prefer a single policy method. Phasing out in favor of {#policy_field}.
    def self.composite_perm(field_name, permissions:, mode:, **field_attrs)
      field field_name, Boolean, null: false, **field_attrs

      case mode
      when :any
        define_method(field_name) do
          permissions.any? do |permission|
            current_permission?(permission: :"can_#{permission}", entity: object)
          end
        end
      when :all
        define_method(field_name) do
          permissions.all? do |permission|
            current_permission?(permission: :"can_#{permission}", entity: object)
          end
        end
      else
        raise 'unrecognized permission mode'
      end
    end

    # Declares a Boolean field resolved by calling a predicate on an HMIS instance policy for the parent object.
    # Does not accept a `policy_override`, the policy resource is always the loaded object.
    # Could be adapted to accept an override for the policy type in the future, for example if we have multiple policy types for the same resource.
    #
    # @param name [Symbol] field basename; trailing `?` is dropped for the GraphQL name
    # @param policy_method_name [Symbol] policy predicate (e.g. `:can_edit?`); default is `:"#{field_name}?"` derived from `name`
    # @param field_attrs [Hash] extra kwargs forwarded to GraphQL `field` (e.g. `description:`)
    def self.policy_field(name, policy_method_name: nil, **field_attrs)
      define_policy_field(
        name,
        policy_method_name: policy_method_name,
        global: false,
        **field_attrs,
      )
    end

    # Declares a Boolean field for a Global (DataSource-scoped) Policy: by default `policy_for(object.class, policy_type: …).<predicate>?`.
    #
    # Use when the answer should not depend on instance-level policy state (e.g. per-project permissions), but on data-source–wide
    # permissions keyed off a Global policy class.
    #
    # @param policy_override [Hash] optional per-field overrides for `policy_for`:
    #   - `:policy_type` — passed to `policy_for` when present; otherwise {.default_policy_type}
    #   - `:resource` — explicit first argument to `policy_for` (a model class or record) when it must differ from `object.class`
    def self.global_policy_field(name, policy_override: {}, policy_method_name: nil, **field_attrs)
      define_policy_field(
        name,
        policy_override: policy_override,
        policy_method_name: policy_method_name,
        global: true,
        **field_attrs,
      )
    end

    # private helper for policy_field / global_policy_field
    def self.define_policy_field(name, policy_override: {}, policy_method_name:, global: false, **field_attrs)
      field_name = name.to_s.delete_suffix('?').to_sym
      method_base = (policy_method_name || field_name).to_s.delete_suffix('?')
      query_method = :"#{method_base}?"

      field field_name, Boolean, null: false, **field_attrs

      define_method(field_name) do
        policy_type = policy_override[:policy_type] || default_policy_type

        policy = if policy_override[:resource]
          policy_for(policy_override[:resource], policy_type: policy_type)
        elsif global
          policy_for(object.class, policy_type: policy_type)
        else
          policy_for(object, policy_type: policy_type)
        end

        !!policy.public_send(query_method)
      end
    end
    private_class_method :define_policy_field
  end
end
