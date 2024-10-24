###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

class Hmis::Form::DefinitionValidator
  def self.perform(...)
    new.perform(...)
  end

  # @param [Hash] document is a form definition document {'item' => [{...}] }
  # @param [role] role of the form as string ('INTAKE', 'CLIENT', etc). If not provided, HUD rule validation will not occur.
  # @param [boolean] skip_cded_validation if true, skip validating CDEDs
  def perform(document, role = nil, skip_cded_validation: false)
    @issues = HmisErrors::Errors.new

    # Validate JSON shape against JSON Schema
    check_json_schema(document)
    # Check Link IDs
    all_ids = check_ids(document)
    # Check references
    check_references(document, all_ids)
    # Check mutually exclusive attributes ("one of" on conditional objects)
    check_mutually_exclusive_attributes(document)
    # Check HUD requirements
    check_hud_requirements(all_ids, role) if role

    check_cdeds(document, role) if role && !skip_cded_validation

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

  # Keys that are mutually exclusive. Exactly 1 of these keys must be present on their parent object.
  ONE_OF_BOUND_VALUES = ['value_number', 'value_date', 'value_local_constant', 'question'].freeze
  ONE_OF_ENABLE_WHEN_SOURCES = ['question', 'local_constant'].freeze
  ONE_OF_ENABLE_WHEN_ANSWERS = ['answer_code', 'answer_codes', 'answer_group_code', 'answer_number', 'answer_boolean', 'answer_date', 'compare_question'].freeze
  ONE_OF_AUTOFILL_VALUES = ['value_code', 'value_number', 'value_boolean', 'value_question', 'sum_questions', 'formula'].freeze

  # Ensure that mutually exclusive attributes are set correctly. These are objects where there must be exactly 1 key present, out of a set of keys.
  def check_mutually_exclusive_attributes(document)
    validate_one_of = lambda do |hash, keys, message_prefix:|
      keys_present = hash.slice(*keys).compact.keys
      return if keys_present.size == 1 # valid

      add_issue("#{message_prefix} must have exactly one of: [#{keys.join(', ')}]. Found keys: [#{keys_present.join(', ')}]")
    end

    link_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        link_id = child_item['link_id']

        if child_item.key?('bounds')
          child_item['bounds'].each_with_index do |bound, idx|
            validate_one_of.call(bound, ONE_OF_BOUND_VALUES, message_prefix: "Bound #{idx + 1} on Link ID #{link_id}")
            # TODO: validate that the value_x field is compatible with the current question type
          end
        end

        if child_item.key?('enable_when')
          child_item['enable_when'].each_with_index do |enable_when, idx|
            msg = "EnableWhen #{idx + 1} on Link ID #{link_id}"
            validate_one_of.call(enable_when, ONE_OF_ENABLE_WHEN_SOURCES, message_prefix: msg)
            validate_one_of.call(enable_when, ONE_OF_ENABLE_WHEN_ANSWERS, message_prefix: msg)
            # TODO: validate that the {source}{operator}{answer} are all compatible. We attempt to ensure this validity in the form property editor,
            # but we do not validate it here. For example:
            # - if source is a question, the answer field should be compatible with the question type (eg shouldn't compare STRING=DATE)
            # - if source is a local constant, the answer field should be compatible local constant type (eg shouldn't compare STRING=DATE)
            # - if operator is special boolean operator (EXISTS/ENABLED), then the answer type should always be boolean
            # - certain comparison operators should only be used for certain question types (eg can't use LESS_THAN on a STRING type)
          end
        end

        if child_item.key?('autofill_values')
          child_item['autofill_values'].each_with_index do |autofill_value, idx|
            validate_one_of.call(autofill_value, ONE_OF_AUTOFILL_VALUES, message_prefix: "EnableWhen #{idx + 1} on Link ID #{link_id}")
            next unless autofill_value.key?('autofill_when')

            autofill_value['autofill_when'].each_with_index do |autofill_when, idx2|
              msg = "Autofill #{idx} condition #{idx2 + 1} on Link ID #{link_id}"
              validate_one_of.call(autofill_when, ONE_OF_ENABLE_WHEN_SOURCES, message_prefix: msg)
              validate_one_of.call(autofill_when, ONE_OF_ENABLE_WHEN_ANSWERS, message_prefix: msg)
            end
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

  def missing_cded_error(item, owner_type, cded_key)
    RuntimeError.new("Item #{item['link_id']} has a custom_field_key mapping, but the CDED does not exist in the database. key = #{cded_key.inspect}, owner_type = #{owner_type.inspect}")
  end

  def data_source
    GrdaWarehouse::DataSource.hmis.first
  end

  def get_cded(item, role)
    @cdeds_by_owner_key ||= Hmis::Hud::CustomDataElementDefinition.order(:id).
      where(data_source: data_source).
      index_by { |cded| [cded.owner_type, cded.key] }

    cded_key, record_type = item['mapping'].values_at('custom_field_key', 'record_type')
    possible_owner_types = []
    if record_type
      possible_owner_types = [Hmis::Form::RecordType.find(record_type).owner_type]
    else
      case role
      when 'SERVICE'
        # For Service forms, the CDED owner is allowed to be Service OR CustomService
        possible_owner_types = ['Hmis::Hud::Service', 'Hmis::Hud::CustomService']
      when 'NEW_CLIENT_ENROLLMENT'
        # For New Client Enrollment forms, the CDED owner is allowed to be Client OR Enrollment
        possible_owner_types = ['Hmis::Hud::Client', 'Hmis::Hud::Enrollment']
      else
        possible_owner_types = [
          Hmis::Form::Definition.owner_class_for_role(role)&.sti_name,
        ]
      end
    end

    possible_cdeds = possible_owner_types.map do |owner_type|
      @cdeds_by_owner_key[[owner_type, cded_key]]
    end
    possible_cdeds.compact!
    cded = possible_cdeds.first
    raise missing_cded_error(item, possible_owner_types, cded_key) unless cded

    cded
  end

  def check_cdeds(document, role)
    cded_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        cded_check.call(child_item)
        link_id = child_item['link_id']
        mapping = child_item['mapping']
        next unless mapping&.key?('custom_field_key')

        cded_key = mapping['custom_field_key']
        next unless cded_key

        cded = get_cded(child_item, role)

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
