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
    field :true_user, Application::User, null: true
    field :object_changes, Types::JsonObject, null: true, description: 'Format is { field: { fieldName: "GQL field name", displayName: "Human readable name", values: [old, new] } }'
    # TODO: add impersonation user / true user, and display it in the interface

    available_filter_options do
      arg :audit_event_record_type, [ID]
      arg :user, [ID]
    end

    # User-friendly display name for item_type
    def record_name
      case object.item_type
      when 'Hmis::Hud::Assessment'
        'CE Assessment'
      when 'Hmis::Hud::Event'
        'CE Event'
      when 'Hmis::Hud::CustomClientAddress'
        return 'Move-in Address' if item_attributes['enrollment_address_type'] == Hmis::Hud::CustomClientAddress::ENROLLMENT_MOVE_IN_TYPE

        'Address'
      when 'Hmis::Hud::CustomClientContactPoint'
        return 'Email Address' if item_attributes['system'] == 'email'
        return 'Phone Number' if item_attributes['system'] == 'phone'

        'Contact Information'
      when 'Hmis::Hud::Disability'
        HudUtility2024.disability_type(item_attributes['DisabilityType']) || 'Disability'
      # TODO: Add back CDE label more efficiently? The below causes N+1, and doesn't work for CDE destroy actions.
      # We could look at `item_attributes['data_element_definition_id']` to determine the label, but it would still be N+1.
      # when 'Hmis::Hud::CustomDataElement'
      #   changed_record&.data_element_definition&.label
      else
        object.item_type.demodulize.gsub(/^Custom(Client)?/, '').
          underscore.humanize.titleize
      end
    end

    def graphql_type
      # maybe there's a way to map these from codegen?
      case object.item_type
      when 'Hmis::Hud::Assessment'
        'CeAssessment'
      else
        object.item_type.demodulize.gsub(/^Custom/, '')
      end
    end

    # NOTE: will be nil if this is a 'destroy' event
    private def changed_record
      load_ar_association(object, :item)
    end

    # Attributes from the object or the current value
    # NOTE: Should ONLY be used to look at fields that don't change. It does not represent the state at any particular time.
    private def item_attributes
      object.object || changed_record&.attributes || {}
    end

    def user
      return unless object.whodunnit
      # 'unauthenticated' matches user_for_paper_trail in ApplicationController.
      # This happens when a Job updates records, which we should display as System changes.
      return User.system_user if object.whodunnit == 'unauthenticated'

      user_id = [
        # User user_id if available
        object.user_id,
        # Otherwise use whodunnit
        object.whodunnit&.match?(/^\d+$/) ? object.whodunnit : nil,
        object.whodunnit&.match?(whodunnit_impersonator_pattern) ? object.whodunnit.sub(whodunnit_impersonator_pattern, '\2') : nil,
      ].find(&:present?)

      Hmis::User.find_by(id: user_id)
    end

    def true_user
      user_id = [
        # Don't return if not impersonating (i.e. user == true_user), use true_user_id if available
        object.user_id != object.true_user_id ? object.true_user_id : nil,
        # Use whodunnit if not
        object.whodunnit&.match?(whodunnit_impersonator_pattern) ? object.whodunnit.sub(whodunnit_impersonator_pattern, '\1') : nil,
      ].find(&:present?)

      Hmis::User.find_by(id: user_id)
    end

    def object_changes
      result = object.object_changes
      return unless result.present?

      result = transform_changes(object, result).map do |key, value|
        # Best-effort guess at GQL field name for this attribute
        field_name = key.underscore.camelize(:lower)

        values = value.map do |val|
          next unless val.present?

          if val.is_a?(Array)
            val.map { |v| safe_enum_for_value(field_name, v) }
          else
            safe_enum_for_value(field_name, val)
          end
        end

        # hide certain changes (SSN/DOB) if unauthorized
        values = 'changed' if changed_record && !authorize_field(changed_record, key)

        [
          field_name,
          {
            'fieldName' => field_name,
            'displayName' => key.titleize(keep_id_suffix: true),
            'values' => values,
          },
        ]
      end.to_h

      result
    end

    # Based on a possible graphql field name and a raw value, return the GQL Enum value for it
    # For example: (name: 'tanfTransportation', value: 1) => 'YES'
    private def safe_enum_for_value(name, value)
      return nil unless value.present?

      # Try to find the enum that maps to this field (if any)
      gql_schema = "Types::HmisSchema::#{graphql_type}".safe_constantize
      gql_enum = Hmis::Hud::Processors::Base.graphql_enum(name, gql_schema)
      return value unless gql_enum

      # Special case Service TypeProvided enum, which uses a composite value.
      value = [item_attributes['RecordType'], value].join(':') if object.item_type == 'Hmis::Hud::Service' && name == 'typeProvided'

      # Find enum member that matches this value
      member = gql_enum.enum_member_for_value(value)

      # If value wasn't valid for the enum, just return the raw value so it's still visible
      return value unless member.present?

      member.first
    end

    private def whodunnit_impersonator_pattern
      /^(\d+) as (\d+)$/
    end
  end
end
