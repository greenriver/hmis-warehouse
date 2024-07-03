###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::DefinitionValidator
  def self.perform(...)
    new.perform(...)
  end

  # @param [Hash] document is a form definition document {'item' => [{...}] }
  # @param [role] role of the form as string ('INTAKE', 'CLIENT', etc). If not provided, HUD rule validation will not occur.
  # @param [owner_type] owner_type of the form, such as Hmis::Hud::CustomAssessment
  # @param [boolean] is_publishing if true, validate CDEDs
  def perform(document, role = nil, owner_type = nil, is_publishing = false)
    @issues = HmisErrors::Errors.new

    # Validate JSON shape against JSON Schema
    check_json_schema(document)
    # Check Link IDs
    all_ids = check_ids(document)
    # Check references
    check_references(document, all_ids)
    # Check HUD requirements
    check_hud_requirements(all_ids, role) if role

    check_cdeds(document, owner_type) if is_publishing

    @issues.errors
  end

  protected

  def add_issue(msg)
    # TODO: resolve more details (e.g. link_id, section, actual severity level)
    @issues.add(:definition, full_message: msg, severity: :error)
  end

  def check_json_schema(document)
    schema_errors = Hmis::Form::Definition.validate_schema(document)
    schema_errors.each do |e|
      # Try to figure out which Link ID the error is on
      item_path = /(\/item\/[0-9]){1,}/.match(e.to_s)&.try(:[], 0)&.split('/')&.
        compact_blank&.
        map { |s| Integer(s, exception: false) || s }
      link_id = document.dig(*item_path, 'link_id') if item_path
      if link_id
        msg = "Schema error on item '#{link_id}': #{e}"
        @issues.add(msg)
      else
        @issues.add(e.to_s)
      end
    end
  end

  def check_ids(document)
    seen_link_ids = Set.new

    recur_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        link_id = child_item['link_id']
        add_issue("Missing link ID: #{child_item}") unless link_id.present?
        add_issue("Duplicate link ID: #{link_id}") if seen_link_ids.include?(link_id)

        seen_link_ids.add(link_id)

        # Ensure pick list reference is valid
        add_issue("Invalid pick list for Link ID #{link_id}: #{child_item['pick_list_reference']}") if child_item['pick_list_reference'] && allowed_pick_list_references.exclude?(child_item['pick_list_reference'])

        recur_check.call(child_item)
      end
    end
    recur_check.call(document)
    seen_link_ids
  end

  # FIXME: this element has dummy values that do not validate correctly
  KNOWN_BAD_REFS = Set.new(['mci_clearance_value'])

  def check_references(document, all_ids)
    link_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        link_id = child_item['link_id']

        if child_item.key?('bounds')
          child_item['bounds'].map { |h| h['question'] }.compact.each do |reference|
            add_issue("Invalid link ID reference: #{reference} in 'bounds' prop of #{link_id}") unless all_ids.include?(reference)
          end
        end

        if child_item.key?('enable_when') && !link_id.in?(KNOWN_BAD_REFS)
          child_item['enable_when'].flat_map { |h| h.values_at('question', 'compare_question') }.compact.each do |reference|
            add_issue("Invalid link ID reference: #{reference} in 'enable_when' prop of #{link_id}") unless all_ids.include?(reference)
          end
        end

        if child_item.key?('autofill_values')
          child_item['autofill_values'].map { |h| h.values_at('value_question', 'sum_questions') }.flatten.compact.each do |reference|
            add_issue("Invalid link ID reference: #{reference} in 'autofill_values' prop of #{link_id}") unless all_ids.include?(reference)
          end
          child_item['autofill_values'].map { |h| h.values_at('autofill_when') }.flatten.compact.flat_map { |h| h.values_at('question', 'compare_question') }.compact.each do |reference|
            add_issue("Invalid link ID reference: #{reference} in 'autofill_when' prop of #{link_id}") unless all_ids.include?(reference)
          end
        end

        link_check.call(child_item)
      end
    end
    link_check.call(document)
  end

  # Fail if there are link_ids that are required for this role that aren't present in the form,
  # For example if Destination missing on the Exit Assessment.
  # This only validates presence of particular Link IDs, it does NOT validate that they are collecting the correct fields, have the
  # correct type and rule, etc. It is expected that the caller uses `set_hud_requirements` to set the correct HUD rules.
  def check_hud_requirements(all_ids, role)
    rule_module = HmisUtil::HudAssessmentFormRules2024.new

    required_link_ids = rule_module.required_link_ids_for_role(role)
    return unless required_link_ids.any?

    missing_link_ids = required_link_ids - all_ids
    add_issue("Missing required link IDs for role #{role}: #{missing_link_ids.join(', ')}") if missing_link_ids.any?
  end

  # Introspect on GraphQL schema to get a superset of allowed values for `pick_list_reference`.
  # This list includes ALL enums in the HUD schema, so it includes some enums
  # that don't make sense as pick lists.
  def allowed_pick_list_references
    @allowed_pick_list_references ||= begin
      enums = []
      collect_enums = ->(parent) {
        parent.constants.each do |name|
          child = parent.const_get(name)
          if child.is_a? Class
            enums << child.graphql_name if child < Types::BaseEnum
          elsif child.is_a? Module
            collect_enums.call(child)
          end
        end
      }

      # Include all enums in Types::HmisSchema::Enums namespace
      collect_enums.call(Types::HmisSchema::Enums)
      # Include all enums in Types::Forms::Enums namespace
      collect_enums.call(Types::Forms::Enums)
      # Include all pick list types
      enums += Types::Forms::Enums::PickListType.values.keys
      enums.to_set
    end
  end

  def check_cdeds(document, owner_type)
    cded_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        cded_check.call(child_item)

        mapping = child_item['mapping']
        next unless mapping&.key?('custom_field_key')

        cded_key = mapping['custom_field_key']
        cded = Hmis::Hud::CustomDataElementDefinition.where(key: cded_key, owner_type: owner_type).first

        link_id = child_item['link_id']

        raise("Item #{link_id} has a custom_field_key mapping, but the CDED does not exist in the database. key = #{cded_key}, owner_type = #{owner_type}") unless cded

        item_type = child_item['type']
        cded_type = cded.field_type

        case item_type
        when 'GROUP', 'OBJECT', 'FILE', 'IMAGE'
          # We don't expect these types to have custom field mappings. If they do, raise an error
          raise "Item #{link_id} has type #{item_type}, so it should not have a custom_field_key"
        when 'DISPLAY'
          # DISPLAY types should really be in the above category too,
          # but we have existing cases that store an autofill value
          next
        when 'STRING', 'TEXT', 'TIME_OF_DAY', 'CHOICE', 'OPEN_CHOICE'
          raise_bad_type_match(link_id, item_type, cded_key, cded_type) unless ['string', 'text'].include?(cded_type)
        when 'BOOLEAN'
          raise_bad_type_match(link_id, item_type, cded_key, cded_type) unless cded_type == 'boolean'
        when 'DATE'
          raise_bad_type_match(link_id, item_type, cded_key, cded_type) unless ['date', 'string', 'text'].include?(cded_type)
        when 'CURRENCY'
          raise_bad_type_match(link_id, item_type, cded_key, cded_type) unless ['float', 'string', 'text'].include?(cded_type)
        when 'INTEGER'
          raise_bad_type_match(link_id, item_type, cded_key, cded_type) unless ['float', 'integer', 'string', 'text'].include?(cded_type)
        else
          raise "Item #{link_id} has unexpected item type #{item_type}"
        end
      end
    end
    cded_check.call(document)
  end

  private def raise_bad_type_match(link_id, item_type, cded_key, cded_type)
    raise "Item #{link_id} has type #{item_type}, but its custom field key #{cded_key} has an incompatible type #{cded_type}"
  end
end
