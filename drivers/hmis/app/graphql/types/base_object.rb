###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseObject < GraphQL::Schema::Object
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    def current_user
      context[:current_user]
    end

    def self.page_type
      @page_type ||= BasePaginated.create(self)
    end

    def self.hud_field(name, type = nil, **kwargs)
      return field name, type, **kwargs unless configuration.present?

      config = configuration.transform_keys { |k| k.to_s.underscore }[name.to_s]
      type ||= hud_to_gql_type_map[config[:type]] if config.present?
      raise "No type for #{name}" unless type.present?

      nullable = kwargs[:null].nil? && config.present? ? config[:null] : kwargs[:null]
      args = kwargs.except(:null)
      field name, type, null: nullable, **args
    end

    def self.yes_no_missing_field(name, description = nil, **kwargs)
      field name, Boolean, description, **kwargs
    end

    def resolve_yes_no_missing(value, yes_value: 1, no_value: 0, null_value: 99)
      case value
      when yes_value
        true
      when no_value
        false
      when null_value
        nil
      end
    end

    def resolve_null_enum(value)
      value == ::HUD.ignored_enum_value ? nil : value
    end

    def load_ar_association(object, association, scope: nil)
      dataloader.with(Sources::ActiveRecordAssociation, association, scope).load(object)
    end

    def self.hud_to_gql_type_map
      {
        string: String,
        integer: Integer,
        datetime: GraphQL::Types::ISO8601DateTime,
        date: GraphQL::Types::ISO8601Date,
      }.freeze
    end

    def self.configuration
      nil
    end
  end
end
