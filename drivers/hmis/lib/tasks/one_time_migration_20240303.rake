# frozen_string_literal: true

desc 'One time data migration to transform link_ids into valid identifiers'
# rails driver:hmis:migrate_hmis_link_ids
task migrate_hmis_link_ids: [:environment] do
  Hmis::Form::Definition.transaction do
    OneTimeMigration20230303.new.perform
    # raise ActiveRecord::Rollback
  end
end

class OneTimeMigration20230303
  def perform
    update_form_processors
    update_form_definitions
  end

  def update_form_processors
    Hmis::Form::FormProcessor.where.not(values: nil).find_each do |processor|
      processor.values = processor.values.transform_keys do |key|
        transform_identifier(key)
      end
      processor.save!
    end
  end

  def update_form_definitions
    Hmis::Form::Definition.find_each do |definition|
      next unless definition.valid?

      seen = Set.new
      walk_nodes(definition.definition) do |node|
        next unless node['link_id'].present?

        link_id = node['link_id']
        node['link_id'] = transform_identifier(link_id) if link_id
        raise "duplicate link_id for #{link_id}" if node['link_id'].in?(seen)

        seen.add(node['link_id'])

        # try to find any question id references in the item definition
        node['enable_when']&.each do |props|
          props['question'] = transform_identifier(props['question']) if props['question']
          props['compare_question'] = transform_identifier(props['compare_question']) if props['compare_question']
        end

        node['autofill_values']&.each do |props|
          props['value_question'] = transform_identifier(props['value_question']) if props['value_question']
          props['sum_questions']&.map! { |value| transform_identifier(value) }
          props['autofill_when']&.each do |child_props|
            child_props['question'] = transform_identifier(child_props['question']) if child_props['question']
            child_props['compare_question'] = transform_identifier(child_props['compare_question']) if child_props['compare_question']
          end
        end
      end
      definition.save!
    end
  end

  RESERVED_WORDS = ['break', 'case', 'catch', 'class', 'const', 'continue', 'debugger', 'default', 'delete', 'do', 'else', 'export', 'extends', 'false', 'finally', 'for', 'function', 'if', 'import', 'in', 'instanceof', 'new', 'null', 'return', 'super', 'switch', 'this', 'throw', 'true', 'try', 'typeof', 'var', 'void', 'while', 'with'].to_set.freeze
  VALID_IDENTIFIER_RGX = /\A[a-zA-Z_$][a-zA-Z0-9_$]*\z/
  def valid_identifier?(value)
    value =~ VALID_IDENTIFIER_RGX && !value.in?(RESERVED_WORDS)
  end

  def transform_identifier(original_value)
    value = original_value

    # the value is already a valid JS identifier
    return value if valid_identifier?(value)

    value = value.strip
    # value is just a number
    value = value =~ /\A[0-9]+\z/ ? "q_#{value}" : value
    # leading number with a period seems to be HUD ref numbers like "2.02.6"
    value = value =~ /\A[^a-z]+\./i ? "hud_#{value}" : value
    # camelize hyphenated strings or spaces
    value = value.gsub(/(-| )+([a-z])/) { Regexp.last_match(2).upcase }
    # replace dots and lingering hyphens with an underscore
    value = value.gsub(/[-.]/, '_')

    raise "failed to transform link id #{original_value}" unless valid_identifier?(value)

    # puts "transform: #{[original_value, value].join(" => ")}"
    value
  end

  def walk_nodes(node, &block)
    return if node.blank?

    block.call(node)
    children = node['item']
    children&.each { |child| walk_nodes(child, &block) }
  end
end
