###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
      @page_type ||= BasePaginated.build(self)
    end

    def self.filter_options_type(name = nil, omit: [])
      raise 'Name must be supplied for filter options type if filter options are omitted' if name.nil? && omit.present?

      @filter_options = {} unless @filter_options.present?
      @filter_options[name] ||= BaseFilterOptions.build(self, name: name, omit: omit, &@available_filter_options_block)
    end

    def self.available_filter_options(&block)
      @available_filter_options_block = block
    end

    def self.audit_event_type(**args)
      @audit_event_type ||= BaseAuditEvent.build(self, **args)
    end

    def self.yes_no_missing_field(name, description = nil, **kwargs)
      field name, Boolean, description, **kwargs

      define_method name do
        resolve_yes_no_missing(object.send(name))
      end
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
      value == ::HudUtility.ignored_enum_value ? nil : value
    end

    def load_ar_association(object, association, scope: nil)
      dataloader.with(Sources::ActiveRecordAssociation, association, scope).load(object)
    end

    # Infers type and nullability from warehouse configuration
    def self.hud_field(name, type = nil, **kwargs)
      return field name, type, **kwargs unless configuration.present?

      config = configuration.transform_keys { |k| k.to_s.underscore }[name.to_s]

      if config.present? && !type.present?
        type = hud_to_gql_type_map[config[:type]]
        type = Float if config[:type] == :string && config[:check] == :money
      end

      raise "No type for #{name}" unless type.present?

      nullable = kwargs[:null].nil? && config.present? ? config[:null] : kwargs[:null]
      args = kwargs.except(:null)
      field name, type, null: nullable, **args
    end

    def self.configuration
      nil
    end

    def self.access_field(name = :access, class_name: nil, **field_attrs, &block)
      field(name, BaseAccess.build(self, class_name: class_name, &block), null: false, **field_attrs)

      define_method(name) do
        object
      end
    end

    def self.hud_to_gql_type_map
      {
        string: String,
        integer: Integer,
        datetime: GraphQL::Types::ISO8601DateTime,
        date: GraphQL::Types::ISO8601Date,
      }.freeze
    end

    # Does the current user the given permission on entity?
    # @param permission [Symbol] :can_do_foo
    # @param entity [#record] Client, project, etc
    def current_permission?(permission:, entity:)
      return false unless current_user&.present?

      # Just return false if we don't have this permission at all for anything
      return false unless current_user.send("#{permission}?")

      loader, subject = current_user.entity_access_loader_factory(entity) do |record, association|
        load_ar_association(record, association)
      end
      raise "Missing loader for #{entity.class.name}##{entity.id}" unless loader

      dataloader.with(Sources::UserEntityAccessSource, current_user, loader).load([subject, permission])
    end
  end
end
