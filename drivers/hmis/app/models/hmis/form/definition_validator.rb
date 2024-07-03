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
  def perform(document, _role = nil)
    @issues = HmisErrors::Errors.new

    # Validate JSON shape against JSON Schema
    check_json_schema(document)
    # Check Link IDs
    all_ids = check_ids(document)
    # Check references
    check_references(document, all_ids)
    check_mutually_exclusive_attributes(document)

    # TODO: Check HUD requirements (requires 'role')

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
  ONE_OF_ENABLE_WHEN_ANSWERS = ['answer_code', 'answer_codes', 'answer_group_code', 'answer_number', 'answer_boolean', 'compare_question'].freeze
  ONE_OF_AUTOFILL_VALUES = ['value_code', 'value_number', 'value_boolean', 'value_question', 'sum_questions', 'formula'].freeze

  # TODO gig: finish testing this and write tests in the definition validator spec once that gets merged in and i rebase
  # Hmis::Form::DefinitionValidator.new.perform({ "item": [ { "link_id": "foo", "type":"STRING",  "enable_behavior": "ANY",  "enable_when": [{"question": "this", "answer_code": "foooo"}] } ] }.deep_stringify_keys).map(&:full_message)
  # very_invalid = {
  #   item: [
  #     {
  #       link_id: 'foo',
  #       type: 'INTEGER',
  #       text: 'foo',
  #       bounds: [
  #         {
  #           severity: 'error',
  #           type: 'max',
  #           value_number: 10,
  #           value_local_constant: 'something', # invalid
  #         },
  #       ],
  #     },
  #   ],
  # }.deep_stringify_keys

  # Ensure that mutually exclusive attributes are set correctly. These are objects where there must be exactly 1 key present, out of a set of keys.
  def check_mutually_exclusive_attributes(document)
    validate_one_of = lambda do |hash, keys, message_prefix:|
      keys_present = hash.slice(*keys).compact.keys
      return if keys_present.size == 1 # exactly 1 key present, so it's valid

      add_issue("#{message_prefix} must have exactly one of: [#{keys.join(', ')}]. Found keys: [#{keys_present.join(', ')}]")
    end

    link_check = lambda do |item|
      (item['item'] || []).each do |child_item|
        link_id = child_item['link_id']

        if child_item.key?('bounds')
          child_item['bounds'].each_with_index do |bound, idx|
            validate_one_of.call(bound, ONE_OF_BOUND_VALUES, message_prefix: "Bound #{idx + 1} on Link ID #{link_id}")
          end
        end

        if child_item.key?('enable_when')
          child_item['enable_when'].each_with_index do |enable_when, idx|
            msg = "EnableWhen #{idx + 1} on Link ID #{link_id}"
            validate_one_of.call(enable_when, ONE_OF_ENABLE_WHEN_SOURCES, message_prefix: msg)
            validate_one_of.call(enable_when, ONE_OF_ENABLE_WHEN_ANSWERS, message_prefix: msg)
          end
        end

        if child_item.key?('autofill_values')
          child_item['autofill_values'].each_with_index do |autofill_value, idx|
            validate_one_of.call(autofill_value, ONE_OF_AUTOFILL_VALUES, message_prefix: "EnableWhen #{idx + 1} on Link ID #{link_id}")

            autofill_value.dig('autofill_when', []).each_with_index do |autofill_when, idx2|
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
end
