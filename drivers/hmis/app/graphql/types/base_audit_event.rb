###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseAuditEvent < BaseObject
    def self.build(node_class, field_permissions: nil, transform_changes: nil)
      dynamic_name = "#{node_class.graphql_name}AuditEvent"
      klass = Class.new(self) do
        graphql_name(dynamic_name)

        define_method(:schema_type) do
          node_class
        end

        define_method(:transform_changes) do |object, changes|
          return transform_changes.call(object, changes) if transform_changes.present?

          changes
        end

        define_method(:authorize_field) do |record, key|
          return true unless field_permissions[key].present?

          # Check if user has permission to view audit history for this particular field (for example SSN/DOB on Client)
          current_user.permissions_for?(record, *Array.wrap(field_permissions[key]))
        end
      end

      Object.const_set(dynamic_name, klass) unless Object.const_defined?(dynamic_name)
      klass
    end

    field :id, ID, null: false
    field :record_id, ID, null: false, method: :item_id
    field :record_name, String, null: false
    field :graphql_type, String, null: false
    field :event, HmisSchema::Enums::AuditEventType, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :user, Application::User, null: true
    field :object_changes, Types::JsonObject, null: true, description: 'Format is { field: { fieldName: "GQL field name", displayName: "Human readable name", values: [old, new] } }'

    available_filter_options do
      arg :audit_event_record_type, [ID]
      arg :user, [ID]
    end

    def record_name
      case object.item_type
      when 'Hmis::Hud::CustomAssessment'
        'Assessment'
      when 'Hmis::Hud::Assessment'
        'CE Assessment'
      when 'Hmis::Hud::Event'
        'CE Event'
      when 'Hmis::Hud::CustomClientAddress'
        values = object.object || {}
        return 'Move in address' if values['enrollment_address_type'] == Hmis::Hud::CustomClientAddress::ENROLLMENT_MOVE_IN_TYPE

        'Address'
      else
        object.item_type.demodulize.gsub(/^CustomClient/, '').underscore.humanize.titleize
      end
    end

    def graphql_type
      # maybe there's a way to map these from codegen?
      case object.item_type
      when 'Hmis::Hud::CustomAssessment'
        'Assessment'
      when 'Hmis::Hud::Assessment'
        'CeAssessment'
      when 'Hmis::Hud::CeParticipation'
        'CeParticipation'
      else
        object.item_type.demodulize
      end
    end

    def user
      return unless object.whodunnit
      # 'unauthenticated' matches user_for_paper_trail in ApplicationController.
      # This happens when a Job updates records, which we should display as System changes.
      return User.system_user if object.whodunnit == 'unauthenticated'

      # If user was impersonating, return the true user only. If someone performed the action while impersonating, whodunnit stores as '1 as 2' where 1 is the true user.
      user_id = object.whodunnit.sub(/ as [0-9]+$/, '')
      return unless user_id.to_i.to_s == user_id

      Hmis::User.find_by(id: user_id)
    end

    def object_changes
      result = object.object_changes
      return unless result.present?

      changed_record = record
      result = transform_changes(object, result).map do |key, value|
        name = key.camelize(:lower)
        gql_enum = Hmis::Hud::Processors::Base.graphql_enum(name, schema_type)

        values = value.map do |val|
          next unless val.present?
          next val unless gql_enum.present?
          next val.map { |v| v.present? ? gql_enum.key_for(v) : nil } if val.is_a? Array

          gql_enum.key_for(val)
        end

        # hide certain changes (SSN/DOB) if unauthorized
        values = 'changed' if changed_record && !authorize_field(changed_record, key)

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

    private def record
      return object.item if object.item_type.starts_with?('Hmis::')

      # Attempt to convert GrdaWarehouse record to Hmis record
      "Hmis::Hud::#{object.item_type.demodulize}".constantize.with_deleted.find_by(id: object.item_id)
    end
  end
end
