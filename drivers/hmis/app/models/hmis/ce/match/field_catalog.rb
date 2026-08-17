# frozen_string_literal: true

module Hmis::Ce::Match
  # Catalog of CE match fields for the rule builder. This class adapts both client
  # expression fields and CDED/form fields into the builder-facing Field shape
  # used by GraphQL and structured-expression translation.
  class FieldCatalog
    # Pick list reference map lives here to keep it out of the ClientFieldMap implementation/engine layer
    CLIENT_PICK_LIST_REFERENCES = {
      veteran_status: 'NoYesReasonsForMissingData',
      open_enrollment_project_types: 'ProjectType',
      open_enrollment_project_types_excluding_incomplete: 'ProjectType',
      open_referral_project_types: 'ProjectType',
    }.freeze

    def initialize(current_date: Date.current)
      @current_date = current_date
    end

    def client_fields
      client_field_map.fields.map { |client_field| build_client_field(client_field) }
    end

    # Build this catalog from the registry so newly registered PSDE fields are
    # automatically available through the GraphQL field query.
    def psde_fields
      Hmis::Ce::Match::Expression::PsdeFieldRegistry::ALL.map { |psde_field| build_psde_field(psde_field) }
    end

    def custom_assessment_fields_for(data_source_id:, form_definition_identifier:)
      versions = form_versions_for(data_source_id, form_definition_identifier).to_a
      return [] if versions.empty?

      metadata_by_key = Hmis::Form::Definition.merge_pick_list_metadata(versions)

      custom_assessment_cdeds(data_source_id, form_definition_identifier).filter_map do |cded|
        metadata = metadata_by_key[cded.key] || {}

        build_cded_field(cded, **metadata)
      end
    end

    def field_for(field_key)
      namespace, resolved_key = Hmis::Ce::Match::Expression::FieldMap.field_type_for(field_key.to_s)

      case namespace
      when Hmis::Ce::Match::Expression::FieldMap::CLIENT
        client_field = client_field_by_key[resolved_key.to_sym]
        build_client_field(client_field) if client_field
      when Hmis::Ce::Match::Expression::FieldMap::PSDE
        psde_field = Hmis::Ce::Match::Expression::PsdeFieldRegistry[resolved_key]
        build_psde_field(psde_field) if psde_field
      when Hmis::Ce::Match::Expression::FieldMap::CDE
        cded_key = resolved_key.split('.').last
        cded = Hmis::Hud::CustomDataElementDefinition.for_ce_match_conditions.find_by(key: cded_key)
        build_cded_field(cded, **form_metadata_for_cded(cded)) if cded
      end
    rescue ArgumentError
      # Unknown namespaces raise from FieldMap.field_type_for; treat them like
      # other unrecognized keys so hydration can fall back to the raw editor.
      nil
    end

    private

    def client_field_map
      @client_field_map ||= Hmis::Ce::Match::Expression::ClientFieldMap.new(current_date: @current_date)
    end

    def client_field_by_key
      @client_field_by_key ||= client_field_map.fields.index_by(&:key).freeze
    end

    def build_client_field(client_field)
      Field.new(
        id: client_field.key.to_s,
        label: client_field_map.label_for(client_field.key),
        item_type: item_type_for_client_field(client_field),
        multiple: client_field.multiple,
        field_key: client_field.key.to_s,
        source: :CLIENT,
        form_definition_identifier: nil,
        pick_list_reference: client_pick_list_reference(client_field),
        pick_list_options: nil,
      )
    end

    def build_psde_field(psde_field)
      # Keep the psde.* namespace in both identifiers. Besides matching the
      # expression syntax, this prevents collisions with client and CDED fields.
      field_key = Hmis::Ce::Match::Expression::PsdeFieldMap.field_key_for(psde_field.key)

      Field.new(
        id: field_key,
        label: psde_field.label,
        item_type: item_type_for_psde_field(psde_field),
        multiple: psde_field.multiple,
        field_key: field_key,
        source: :PSDE,
        form_definition_identifier: nil,
        pick_list_reference: nil,
        pick_list_options: nil,
      )
    end

    def build_cded_field(cded, item_type: nil, pick_list_reference: nil, pick_list_options: nil)
      Field.new(
        id: cded.id,
        label: cded.label,
        item_type: item_type || item_type_for_cded(cded),
        multiple: cded.repeats || false,
        field_key: Hmis::Ce::Match::Expression::CdeFieldMap.field_key_for(Hmis::Ce::Match::Expression::FieldMap::CUSTOM_ASSESSMENT, cded.key),
        source: :CUSTOM_DATA_ELEMENT,
        form_definition_identifier: cded.form_definition_identifier,
        pick_list_reference: pick_list_reference,
        pick_list_options: pick_list_options,
      )
    end

    # Used as a fallback for CDEDs that can't be mapped to a form item
    def item_type_for_cded(cded)
      case cded.field_type.to_sym
      when :boolean
        'BOOLEAN'
      when :date
        'DATE'
      when :integer, :float
        'INTEGER'
      when :text
        'TEXT'
      when :string
        'STRING'
      else
        raise ArgumentError, "unsupported CDED field type for expression builder field #{cded.key}: #{cded.field_type}"
      end
    end

    def item_type_for_psde_field(psde_field)
      # PSDE registry value types are intentionally storage-agnostic; translate
      # them into the form item types understood by the rule editor.
      case psde_field.value_type
      when :logical
        'BOOLEAN'
      when :numeric
        'INTEGER'
      else
        raise ArgumentError, "unsupported value type for expression builder field #{psde_field.key}: #{psde_field.value_type}"
      end
    end

    def item_type_for_client_field(client_field)
      return 'CHOICE' if client_pick_list_reference(client_field).present?

      case client_field.value_type
      when Hmis::Ce::Match::Expression::ValueType::NUMERIC
        'INTEGER'
      when Hmis::Ce::Match::Expression::ValueType::LOGICAL
        'BOOLEAN'
      when Hmis::Ce::Match::Expression::ValueType::DATETIME
        'DATE'
      when Hmis::Ce::Match::Expression::ValueType::STRING
        'STRING'
      else
        raise ArgumentError, "unsupported value type for expression builder field #{client_field.key}"
      end
    end

    def client_pick_list_reference(client_field)
      CLIENT_PICK_LIST_REFERENCES[client_field.key]
    end

    def custom_assessment_cdeds(data_source_id, form_definition_identifier)
      Hmis::Hud::CustomDataElementDefinition.
        for_ce_match_conditions.
        where(data_source_id: data_source_id, form_definition_identifier: form_definition_identifier).
        order(:key)
    end

    def form_versions_for(data_source_id, form_definition_identifier)
      Hmis::Form::Definition.
        with_role(:CUSTOM_ASSESSMENT).
        # Include published and retired versions because match rules may need to
        # target values collected by older assessment versions.
        published_or_retired.
        where(data_source_id: data_source_id, identifier: form_definition_identifier).
        order(version: :desc, id: :desc)
    end

    def form_metadata_for_cded(cded)
      versions = form_versions_for(cded.data_source_id, cded.form_definition_identifier)
      Hmis::Form::Definition.merge_pick_list_metadata(versions)[cded.key] || {}
    end
  end
end
