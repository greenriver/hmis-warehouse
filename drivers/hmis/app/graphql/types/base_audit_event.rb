###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseAuditEvent < BaseObject
    def self.build(node_class, field_permissions: nil, object_permissions: nil, excluded_keys: nil, transform_changes: nil)
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

        define_method(:authorize_field) do |record, key|
          return true unless field_permissions[key].present?

          # If no record provided, then it's a deleted record, so check general permissions
          return current_user.permission?(*Array.wrap(field_permissions[key])) unless record

          # Check if user has permission to view audit history for this particular field (for example SSN/DOB on Client)
          current_user.permissions_for?(record, *Array.wrap(field_permissions[key]))
        end

        define_method(:authorize_object) do |item_type, record|
          return true unless object_permissions

          return true unless object_permissions[item_type].present?

          return current_user.permission?(*Array.wrap(object_permissions[item_type])) unless record

          return current_user.permission_for?(record, *Array.wrap(object_permissions[item_type]))
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
      client = load_ar_association(object, :hmis_client)
      return client&.masked_name unless current_permission?(permission: :can_view_client_name, entity: client)

      client&.full_name
    end

    def project_name
      load_ar_association(object, :hmis_project)&.project_name
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
      when 'Hmis::Hud::CustomDataElement'
        # Try to label Custom Data Elements based on their definition label
        definition_id = item_attributes['data_element_definition_id']
        custom_data_element_labels_by_id[definition_id] || 'Custom Data Element'
      when 'Hmis::Hud::CustomAssessment'
        # Label Assessment by name (eg "Exit Assessment")
        HudUtility2024.assessment_name_by_data_collection_stage[item_attributes['DataCollectionStage']] ||
          custom_assessment_title ||
          'Assessment'
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

        # hide certain changes (SSN/DOB) if unauthorized
        values = 'changed' unless authorize_field(changed_record, key)

        # hide all changes on certain objects (address, phone) if unauthorized
        values = 'changed' unless authorize_object(object.item_type, changed_record)

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
