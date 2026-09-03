###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class BaseAccess < BaseObject
    def self.build(node_class, class_name: nil, &block)
      Class.new(self) do
        skip_activity_log
        graphql_name(class_name || "#{node_class.graphql_name}Access")
        instance_eval(&block) if block

        field :id, ID, null: false

        def id
          [object.respond_to?(:id) ? object.id : nil, current_user&.id].compact.first
        end
      end
    end

    # Legacy: resolves a single raw permission on `object` via {GraphqlPermissionChecker}. Prefer policy predicates.
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

    # Declares a Boolean field with an explicit resolver block.
    #
    # @param name [Symbol] field basename; trailing `?` is dropped for the GraphQL field name and resolver method
    # @param field_attrs [Hash] extra kwargs forwarded to GraphQL `field` (e.g. `description:`)
    def self.bool_field(name, **field_attrs, &block)
      raise ArgumentError, 'bool_field requires a block' unless block

      field_name = name.to_s.delete_suffix('?').to_sym
      field field_name, Boolean, null: false, **field_attrs
      define_method(field_name, &block)
    end
  end
end
