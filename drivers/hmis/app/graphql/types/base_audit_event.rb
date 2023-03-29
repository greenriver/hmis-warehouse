###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseAuditEvent < BaseObject
    def self.create(node_class)
      Class.new(self) do
        graphql_name("#{node_class.graphql_name}AuditEvent")
        field :item, node_class, null: false
      end
    end

    field :id, ID, null: false
    field :event, HmisSchema::Enums::AuditEventType, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :user, HmisSchema::User, null: true
    field :object_changes, Types::JsonObject, null: true

    def user
      Hmis::Hud::User.find_by(id: object.whodunnit)
    end

    def object_changes
      return YAML.load(object.object_changes, permitted_classes: [Time, Date, Symbol]) if object.object_changes.present?
    end
  end
end
