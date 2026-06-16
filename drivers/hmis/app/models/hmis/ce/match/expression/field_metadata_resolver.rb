# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # needs header comment - what is this class for? discussed maybe moving to gql layer
  class FieldMetadataResolver
    # skip fields that we dont support yet in the expression builder. plan to add support for these fields, link ticket
    def client_fields(excluded: [ClientFieldMap::Fields::DAYS_SINCE_LAST_EXIT.key, ClientFieldMap::Fields::OPEN_ENROLLMENT_PROJECT_TYPES.key])
      field_map = ClientFieldMap.new

      ClientFieldMap::Fields::ALL.reject { |field| excluded.include?(field.key) }.map do |field|
        key = field.key.to_s

        FieldMetadata.new(
          id: key,
          key: key,
          label: field_map.label_for(field.key),
          item_type: graphql_item_type_for(field),
          repeats: false, # we should get this from the field information. "open enrollment project types" for example is an array. (if that's what "repeats" means. maybe "repeats" indicates whether you can select multiple values for matching, which is a different concept than whether the field itself resolves to an array.)
          expression_field: key,
          form_definition_identifier: nil,
          pick_list_options: [],
          pick_list_reference: field.pick_list,
        )
      end
    end

    def custom_assessment_fields_for(data_source_id:, form_definition_identifier:)
      cdeds = Hmis::Hud::CustomDataElementDefinition.
        for_ce_match_conditions.
        where(data_source_id: data_source_id, form_definition_identifier: form_definition_identifier).
        order(:key)

      # CDEDs carry persistence/query metadata, but the user-facing builder
      # labels, item types, repeats flag, and pick lists live on form definition
      # items. Build the item metadata once per form identifier so each CDED can
      # be translated into a complete CeMatchField without re-walking every form.
      form_versions = form_versions_for(data_source_id, form_definition_identifier).to_a
      return [] if form_versions.empty?

      metadata_by_key = item_metadata_by_key(form_versions)

      cdeds.map do |cded|
        metadata = metadata_by_key.fetch(cded.key)

        FieldMetadata.new(
          id: cded.id,
          key: cded.key,
          label: cded.label,
          item_type: metadata.fetch(:item_type), # use form item type instead of cded.field_type
          repeats: cded.repeats,
          expression_field: CdeFieldMap.field_key_for(FieldMap::CUSTOM_ASSESSMENT, cded.key),
          form_definition_identifier: cded.form_definition_identifier,
          pick_list_options: metadata[:pick_list_reference].present? ? [] : metadata[:pick_list_options] || [],
          pick_list_reference: metadata[:pick_list_reference],
        )
      end
    end

    private

    def graphql_item_type_for(field)
      case field.value_type
      when ValueType::NUMERIC then 'INTEGER'
      when ValueType::LOGICAL then 'BOOLEAN'
      when ValueType::DATETIME then 'DATE'
      when ValueType::STRING
        field.pick_list.present? ? 'CHOICE' : 'STRING'
      else
        raise ArgumentError, "unsupported value type for expression builder field #{field.key}"
      end
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

    # Translate form definition item hashes into display metadata, keyed by
    # CDED key. A CeMatchField is not backed by only a CDED: the CDED tells the
    # expression engine how to query values, while the form item tells the
    # structured builder how to display and validate choices for that field.
    #
    # Newer form versions are visited first so scalar display metadata comes
    # from the latest published/retired item. Inline pick-list options are
    # unioned across versions so historical answer codes remain selectable.
    def item_metadata_by_key(form_versions)
      metadata_by_key = {}

      form_versions.each do |definition|
        definition.walk_definition_nodes do |item|
          key = item.dig('mapping', 'custom_field_key')
          next unless key.present?

          metadata = metadata_by_key[key] ||= { pick_list_options: [] }
          metadata[:item_type] ||= item['type']
          # Form versions are newest-first, so the newest item decides whether
          # this field is reference-backed. If historical versions used a
          # different reference, leave unusual legacy values to the free-text
          # expression builder.
          metadata[:pick_list_reference] = item['pick_list_reference'].presence unless metadata.key?(:pick_list_reference)
          metadata[:pick_list_options] = merge_pick_list_options(metadata[:pick_list_options], options_for_item(item))
        end
      end

      metadata_by_key
    end

    # Keep only the PickListOption fields exposed by GraphQL. Form definition
    # items are JSON hashes, not FormItem GraphQL objects, so translation belongs
    # here before the CeMatchField value object is constructed.
    def options_for_item(item)
      Array.wrap(item['pick_list_options']).map { |option| option.slice('code', 'label', 'secondary_label', 'group_code', 'group_label', 'numeric_value', 'helper_text', 'disabled') }
    end

    # Merge by option code while preserving the newest version's label/metadata
    # when the same code appears in multiple form versions.
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
