# frozen_string_literal: true

desc 'One time data migration to transform link_ids into valid JS identifiers'
# rails driver:hmis:migrate_hmis_link_ids
task migrate_hmis_link_ids: [:environment] do
  Hmis::Form::Definition.transaction do
    OneTimeMigration20230303.new.perform
    byebug
    raise ActiveRecord::Rollback
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
      seen = Set.new
      walk_nodes(definition.definition) do |node|
        puts node.keys.inspect
        link_id = node['link_id']
        node['link_id'] = transform_identifier(link_id) if link_id
        raise "duplicate link_id for #{link_id}" if node['link_id'].in?(seen)

        seen.add(node['link_id'])

        node['enable_when']&.each do |props|
          props['question']&.tap do |value|
            props['question'] = transform_identifier(value)
          end
          props['compare_question']&.tap do |value|
            props['compare_question'] = transform_identifier(value)
          end
        end

        #node['autofill_values']&.tap do |props|
        #  props['value_question']&.tap do |value|
        #    props['value_question'] = transform_identifier(value)
        #  end
        #  props['sum_questions']&.tap do |values|
        #    props['sum_questions'] = values.map { |value| transform_identifier(value) }
        #  end
        #end
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
    # prefix leading number
    value = value =~ /\A[0-9]/ ? "Q#{value}" : value
    # replace dashes with a single underscore
    value = value.gsub('-', '_')
    # replace dots with a double_underscore
    value = value.gsub('.', '__')

    raise "failed to transform link id #{original_value}" unless valid_identifier?(value)

    value
  end

  def walk_nodes(node, &block)
    return if node.blank?

    block.call(node)
    children = node['item']
    children&.each { |child| walk_nodes(child, &block) }
  end
end
