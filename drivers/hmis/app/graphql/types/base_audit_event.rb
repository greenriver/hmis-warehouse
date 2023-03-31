###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseAuditEvent < BaseObject
    def self.build(node_class)
      Class.new(self) do
        graphql_name("#{node_class.graphql_name}AuditEvent")
        field :item, node_class, null: false

        define_method(:schema_type) do
          node_class
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

      result = YAML.load(object.object_changes, permitted_classes: [Time, Date, Symbol]).except('DateUpdated')

      result = result.map do |key, value|
        name = key.camelize(:lower)
        field = Hmis::Hud::Processors::Base.hud_type(name, schema_type)

        values = value.map { |val| field ? field.key_for(val) : val }

        values = 'changed' if key == 'SSN' && !current_user.can_view_full_ssn_for?(object)
        values = 'changed' if key == 'DOB' && !current_user.can_view_dob_for?(object)

        [
          name,
          {
            'fieldName' => name,
            'displayName' => key.titleize,
            'values' => values,
          },
        ]
      end.to_h

      result
    end
  end
end
