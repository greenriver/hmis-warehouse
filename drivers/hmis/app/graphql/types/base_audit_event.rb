###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class BaseAuditEvent < BaseObject
    def self.build(node_class, excluded_keys: nil, transform_changes: nil)
      dynamic_name = "#{node_class.graphql_name}AuditEvent"
      klass = Class.new(self) do
        graphql_name(dynamic_name)

        define_method(:schema_type) do
          node_class
        end

        define_method(:excluded_keys) do
          excluded_keys
        end

        define_method(:transform_changes) do |object, changes|
          return transform_changes.call(object, changes) if transform_changes.present?

          changes
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
    field :client_id, String, null: true
    field :client_name, String, null: true
    field :enrollment_id, String, null: true
    field :project_id, String, null: true
    field :project_name, String, null: true
    # TODO: add impersonation user / true user, and display it in the interface

    available_filter_options do
      arg :enrollment_record_type, [ID]
      arg :client_record_type, [ID]
      arg :user, [ID]
    end

    def client_name
      # intentionally bypasses can_view_client_name permission check, auditing is an admin permission that grants access to view all PII
      client = load_ar_association(object, :hmis_client)
      client&.full_name
    end

    def project_name
      load_ar_association(object, :hmis_project)&.project_name
    end

    # User-friendly display name for item_type
    def record_name
      case object.item_type
      when 'Hmis::RestrictedRecord'
        'Record Restriction'
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
        HudHelper.util.disability_type(item_attributes['DisabilityType']) || 'Disability'
      when 'Hmis::Hud::CustomDataElement'
        # Try to label Custom Data Elements based on their definition label
        definition_id = item_attributes['data_element_definition_id']
        custom_data_element_labels_by_id[definition_id] || 'Custom Data Element'
      when 'Hmis::Hud::CustomAssessment'
        # Label Assessment by name (eg "Exit Assessment")
        HudHelper.util.assessment_name_by_data_collection_stage[item_attributes['DataCollectionStage']] ||
          custom_assessment_title ||
          'Assessment'
      else
        object.item_type.demodulize.gsub(/^Custom(Client)?/, '').
          underscore.humanize.titleize
      end
    end

    def graphql_type
      # A restriction is reported as its restrictable's type, so the synthesized `restricted`
      # change below resolves against a real schema field and renders as Yes/No rather than a raw
      # boolean. Client is the only restrictable type today, and the only one whose schema has a
      # `restricted` field, but reading it off the version keeps this honest as more are added.
      # `record_id` deliberately still reports the restriction row, not the restrictable, so that
      # it means the same thing here as it does for every other record type.
      return graphql_type_for(restrictable_type) if restriction?

      graphql_type_for(object.item_type)
    end

    private def graphql_type_for(item_type)
      # maybe there's a way to map these from codegen?
      case item_type
      when 'Hmis::Hud::Assessment'
        'CeAssessment'
      else
        item_type.demodulize.gsub(/^Custom/, '')
      end
    end

    # The restrictable type is only readable from the version payload. A destroy version can lose
    # it if `object` was never written, so fall back to the one type that can be restricted today.
    private def restrictable_type
      item_attributes&.dig('restrictable_type') || Hmis::RestrictedRecord::CLIENT_RESTRICTABLE_TYPE
    end

    # A restriction row records no meaningful column change of its own: every column is a foreign
    # key or a timestamp, and `deleted_at` is nil on both sides of the destroy. Restricting and
    # unrestricting are reported as an update to the restrictable's `restricted` field instead, so
    # the audit row shows the direction of the change rather than a bare "Create" or "Delete".
    def event
      return 'update' if restriction?

      object.event
    end

    private def restriction?
      object.item_type == 'Hmis::RestrictedRecord'
    end

    private def restriction_object_changes
      # Restricting writes a create and unrestricting writes a destroy, so a destroy is the only
      # version that means "no longer restricted".
      #
      # Versions written before RestrictedRecord.mark! stopped reusing rows can also be updates.
      # Those come from the created_by re-stamp that followed the revive, so they exist only when
      # a different user acted. Most were genuine restrictions, but mark! re-stamped created_by on
      # an already-active row too, which restricted nothing; those render as a second restrict row
      # on a client that was already restricted, and nothing on the version tells the two apart.
      # See docs/features/hmis/hmis-restricted-records.md#audit-trail.
      restricted = object.event != 'destroy'

      {
        'restricted' => {
          'fieldName' => 'restricted',
          'displayName' => 'Restricted',
          'values' => [!restricted, restricted],
        },
      }
    end

    private def custom_assessment_title
      ca = load_ar_scope(scope: Hmis::Hud::CustomAssessment.with_deleted, id: object.item_id)
      ca ? load_ar_association(ca, :definition)&.title : nil
    end

    # NOTE: will be nil if this is a 'destroy' event
    private def changed_record
      load_ar_association(object, :item)
    end

    # Attributes from the object or the current value
    # NOTE: Should ONLY be used to look at fields that don't change. It does not represent the state at any particular time.
    private def item_attributes
      return object.object_changes&.transform_values(&:last) if object.event == 'create'

      object.object || changed_record&.attributes
    end

    def user
      return unless object.whodunnit
      # 'unauthenticated' matches user_for_paper_trail in ApplicationController.
      # This happens when a Job updates records, which we should display as System changes.
      return Hmis::User.system_user if object.whodunnit == 'unauthenticated'

      Hmis::User.find_by(id: object.clean_user_id)
    end

    def true_user
      return unless object.whodunnit

      Hmis::User.find_by(id: object.clean_true_user_id)
    end

    # Fields that are always excluded.
    # Fields keys should match our DB casing, consult schema to determine appropriate casing.
    ALWAYS_EXCLUDED_KEYS = [
      'id',
      'DateCreated',
      'DateUpdated',
      'DateDeleted',
      'source_hash',
    ].freeze

    def object_changes
      return restriction_object_changes if restriction?

      result = object.object_changes
      return unless result.present?

      result = result.reject do |key|
        key.underscore.end_with?('_id') || ALWAYS_EXCLUDED_KEYS.include?(key) || excluded_keys&.include?(key)
      end
      return unless result.any?

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

        # Skip if changes are empty, or if the change is `nil=>99` or `99=>nil`. This is not meaningful to show in the UI.
        next if values.map { |v| v == 99 ? nil : v }.compact.empty?

        [
          field_name,
          {
            'fieldName' => field_name,
            'displayName' => key.titleize(keep_id_suffix: true),
            'values' => values,
          },
        ]
      end.compact.to_h
      return unless result.any?

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

    # Mapping { ID => Label } for all custom data element definitions in the data source
    def custom_data_element_labels_by_id
      data_source = load_ar_scope(scope: GrdaWarehouse::DataSource.hmis, id: current_user.hmis_data_source_id)
      definitions = load_ar_association(data_source, :custom_data_element_definitions)

      definitions.map { |cded| [cded.id, cded.label] }.to_h
    end
  end
end
