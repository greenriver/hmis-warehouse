###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseAuditEvent < BaseObject
    def self.build(node_class, field_permissions: nil, transform_changes: nil)
      Class.new(self) do
        graphql_name("#{node_class.graphql_name}AuditEvent")
        field :item, node_class, null: false

        define_method(:schema_type) do
          node_class
        end

        define_method(:transform_changes) do |object, changes|
          return transform_changes.call(object, changes) if transform_changes.present?

          changes
        end

        define_method(:authorize_field) do |object, key|
          authorized = true
          authorized = current_user.permissions_for?(object.item, *Array.wrap(field_permissions[key])) if field_permissions[key].present?
          authorized
        end
      end
    end

    field :id, ID, null: false
    field :event, HmisSchema::Enums::AuditEventType, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :user, Application::User, null: true
    field :object_changes, Types::JsonObject, null: true, description: 'Format is { field: { fieldName: "GQL field name", displayName: "Human readable name", values: [old, new] } }'

    def user
      Hmis::User.find_by(id: object.whodunnit)
    end

    def object_changes
      return unless object.object_changes.present?

      result = YAML.load(object.object_changes, permitted_classes: [Time, Date, Symbol], aliases: true).except('DateUpdated')

      result = transform_changes(object, result).map do |key, value|
        name = key.camelize(:lower)
        field = Hmis::Hud::Processors::Base.hud_type(name, schema_type)

        values = value.map do |val|
          next unless val.present?
          next val unless field.present?
          next val.map { |v| v.present? ? field.key_for(v) : nil } if val.is_a? Array

          field.key_for(val)
        end

        values = 'changed' unless authorize_field(object, key)

        [
          name,
          {
            'fieldName' => name,
            'displayName' => key.titleize(keep_id_suffix: true),
            'values' => values,
          },
        ]
      end.to_h

      result
    end
  end
end
