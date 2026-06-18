# frozen_string_literal: true

module Hmis::Ce::Match
  # Catalog of CE match fields. These can be backed by either client expression fields
  # (see ClientFieldMap), or CustomDataElementDefinitions (see CdeFieldMap).
  # This class adapts both into the builder-facing metadata shape.
  class FieldCatalog # todo @martha - can this still rightly be called a "catalog"?
    def initialize(current_date: Date.current)
      @current_date = current_date
    end

    def client_fields
      client_field_map.fields.map { |client_field| field_for_client_field(client_field) } # todo @martha - rename field_for_client_field
    end

    def custom_assessment_fields_for(data_source_id:, form_definition_identifier:)
      form_versions = form_versions_for(data_source_id, form_definition_identifier).to_a
      return [] if form_versions.empty?

      metadata_by_key = item_metadata_by_key(form_versions)

      custom_assessment_cdeds(data_source_id, form_definition_identifier).filter_map do |cded|
        metadata = metadata_by_key[cded.key] || {}

        field_for_cded(
          cded,
          item_type: metadata[:item_type],
          pick_list_reference: metadata[:pick_list_reference],
          pick_list_options: metadata[:pick_list_reference].present? ? nil : metadata[:pick_list_options].presence,
        )
      end
    end

    # Used by ExpressionTranslator to resolve a field by its key
    # when figuring out the field type and pick list reference.
    # in order to coerce the value for the expression.
    # todo @martha - can this be simplified?
    def field_for(field_key)
      field_key = field_key.to_s
      client_field = client_field_map.fields.find { |field| field.key.to_s == field_key }
      return field_for_client_field(client_field) if client_field

      return unless field_key.start_with?("#{Hmis::Ce::Match::Expression::FieldMap::CDE}.")

      cded_key = field_key.split('.').last
      cded = Hmis::Hud::CustomDataElementDefinition.for_ce_match_conditions.find_by(key: cded_key)
      field_for_cded(cded) if cded
    end

    private

    def client_field_map
      @client_field_map ||= Hmis::Ce::Match::Expression::ClientFieldMap.new(current_date: @current_date)
    end

    def field_for_client_field(client_field)
      Field.new(
        id: client_field.key.to_s,
        label: client_field.label,
        item_type: item_type_for_client_field(client_field),
        multiple: client_field.value_type.multiple,
        field_key: client_field.key.to_s,
        pick_list_reference: client_field.pick_list,
        pick_list_options: nil,
      )
    end

    # todo @martha - what if item_type is nil? it should always be present
    def field_for_cded(cded, item_type: nil, pick_list_reference: nil, pick_list_options: nil)
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

    def item_type_for_client_field(client_field)
      return 'CHOICE' if client_field.pick_list.present?

      case client_field.value_type.base_type
      when :numeric
        'INTEGER'
      when :logical
        'BOOLEAN'
      when :datetime
        'DATE'
      when :string
        'STRING'
      else
        raise "Unsupported CE match field value type: #{value_type.base_type}"
      end
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

    # Newer form versions are visited first so scalar choice metadata comes from
    # the latest published/retired item. Inline options are unioned across
    # versions so historical answer codes remain selectable.
    def item_metadata_by_key(form_versions)
      metadata_by_key = {}

      form_versions.each do |definition|
        definition.walk_definition_nodes do |item|
          key = item.dig('mapping', 'custom_field_key')
          next unless key.present?

          # todo @martha - can `metadata` be simplified?
          metadata = metadata_by_key[key] ||= { pick_list_options: [] }
          metadata[:item_type] ||= item['type'].presence
          metadata[:pick_list_reference] = item['pick_list_reference'].presence unless metadata.key?(:pick_list_reference)
          metadata[:pick_list_options] = merge_pick_list_options(metadata[:pick_list_options], options_for_item(item))
        end
      end

      metadata_by_key
    end

    # Keep only the PickListOption fields exposed by GraphQL.
    # todo @martha - is this necessary?
    def options_for_item(item)
      Array.wrap(item['pick_list_options']).map { |option| option.slice('code', 'label', 'secondary_label', 'group_code', 'group_label', 'numeric_value', 'helper_text', 'disabled') }
    end

    def merge_pick_list_options(existing_options, new_options)
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
