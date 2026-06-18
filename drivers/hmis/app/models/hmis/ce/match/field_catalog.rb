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

    def custom_assessment_fields_for(data_source_id:, form_definition_identifier:)
      form_versions = form_versions_for(data_source_id, form_definition_identifier).to_a
      return [] if form_versions.empty?

      metadata_by_key = item_metadata_by_key(form_versions)

      custom_assessment_cdeds(data_source_id, form_definition_identifier).filter_map do |cded|
        metadata = metadata_by_key[cded.key] || {}

        build_cded_field(cded, **metadata)
      end
    end

    # Used by ExpressionTranslator to resolve field metadata by expression key.
    # If the expression includes a CDED key, attempt to recover type metadata from its
    # form definition (in order to resolve all historical picklist options).
    # Fall back to CDED type if no form identifier is present.
    def field_for(field_key)
      field_key = field_key.to_s
      client_field = client_field_by_key[field_key.to_sym]
      return build_client_field(client_field) if client_field

      return unless field_key.start_with?("#{Hmis::Ce::Match::Expression::FieldMap::CDE}.")

      cded_key = field_key.split('.').last
      cded = Hmis::Hud::CustomDataElementDefinition.for_ce_match_conditions.find_by(key: cded_key)
      build_cded_field(cded, **form_metadata_for_cded(cded)) if cded
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
        pick_list_reference: client_pick_list_reference(client_field),
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
      form_versions = form_versions_for(cded.data_source_id, cded.form_definition_identifier).to_a
      item_metadata_by_key(form_versions)[cded.key] || {}
    end

    # Newer form versions are visited first so scalar choice metadata comes from
    # the latest published/retired item. Inline options are unioned across
    # versions so historical answer codes remain selectable.
    def item_metadata_by_key(form_versions)
      metadata_by_key = {}

      form_versions.each do |definition|
        definition.walk_definition_nodes do |item|
          key = item.dig('mapping', 'custom_field_key')
          next unless key.present?

          form_metadata = metadata_by_key[key] ||= {}
          form_metadata[:item_type] ||= item['type'].presence
          form_metadata[:pick_list_reference] = item['pick_list_reference'].presence unless form_metadata.key?(:pick_list_reference)

          if form_metadata[:pick_list_reference].present?
            form_metadata[:pick_list_options] = nil
          else
            form_metadata[:pick_list_options] = merge_pick_list_options(form_metadata[:pick_list_options], Array.wrap(item['pick_list_options'])).presence
          end
        end
      end

      metadata_by_key
    end

    def merge_pick_list_options(existing_options, new_options)
      existing_options = Array.wrap(existing_options)
      existing_codes = existing_options.pluck('code').to_set

      existing_options + new_options.filter_map do |option|
        code = option['code'] || option[:code]
        next if code.blank? || existing_codes.include?(code)

        existing_codes << code
        option.stringify_keys
      end
    end
  end
end
