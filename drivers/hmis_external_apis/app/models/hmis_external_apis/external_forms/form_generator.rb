###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# render html from a from definition
module HmisExternalApis::ExternalForms
  class FormGenerator
    attr_reader :context
    attr_reader :form_definition
    def initialize(context, form_definition)
      @stack = []
      @context = context
      @form_definition = form_definition # Hmis::Form::Definition record
    end

    delegate :register_field,
             :render_form_input,
             :render_form_textarea,
             :render_numeric_input,
             :render_form_date,
             :render_form_select,
             :render_form_radio_group,
             :render_form_actions,
             :render_form_fieldset,
             :render_section,
             :render_form_checkbox,
             :render_dependent_block,
             :name_from_label,
             to: :context

    def render_node(node)
      # can turn off required fields for easier testing
      # node['required'] = false
      @stack.push(node)
      result = render_dependent_item_wrapper(node) do
        render_node_by_type(node)
      end
      @stack.pop
      return result
    end

    def render_node_by_type(node)
      node_type = node['type']
      case node_type
      when 'STRING'
        render_input_node(node)
      when 'DATE'
        render_date_node(node)
      when 'DISPLAY'
        render_display_node(node)
      when 'BOOLEAN'
        render_boolean_node(node)
      when 'TEXT'
        render_text_node(node)
      when 'GROUP'
        render_group_node(node)
      when 'CHOICE'
        render_choice_node(node)
      when 'INTEGER'
        render_numeric_node(node)
      else
        raise "node type #{node_type} not supported in #{node.inspect}"
      end
    end

    def parent_node
      @stack[-2]
    end

    def render_input_node(node)
      render_form_group(node: node) do
        case node['component']
        when 'PHONE'
          render_form_input(label: node['text'], name: node_name(node), required: node['required'], input_type: 'tel', input_invalid_feedback: 'Enter a valid 10-digit phone number')
        when 'EMAIL'
          render_form_input(label: node['text'], name: node_name(node), required: node['required'], input_type: 'email', input_invalid_feedback: 'Enter a valid email address')
        else
          render_form_input(label: node['text'], name: node_name(node), required: node['required'], input_type: 'text')
        end
      end
    end

    def render_boolean_node(node)
      render_form_group(node: node) do
        render_form_checkbox(label: node['text'], name: node_name(node), required: node['required'])
      end
    end

    def render_numeric_node(node)
      render_form_group(node: node) do
        render_numeric_input(label: node['text'], name: node_name(node), required: node['required'])
      end
    end

    def render_text_node(node)
      render_form_group(node: node) do
        render_form_textarea(label: node['text'], name: node_name(node), required: node['required'])
      end
    end

    def render_date_node(node)
      render_form_group(node: node) do
        render_form_date(legend: node['text'], name: node_name(node), required: node['required'])
      end
    end

    def render_display_node(node)
      classes = case node['component']
      when 'ALERT_INFO'
        'alert alert-info'
      when 'ALERT_WARNING'
        'alert alert-warning'
      when 'ALERT_ERROR'
        'alert alert-danger'
      when 'ALERT_SUCCESS'
        'alert alert-success'
      end

      render_form_group(node: node) do
        context.tag.div(node['text'].html_safe)
        context.tag.div(node['text'].html_safe, class: classes)
      end
    end

    def render_choice_node(node)
      options = resolve_pick_list(node)
      raise "missing options in #{node.inspect}" unless options.present?

      render_form_group(node: node) do
        case node['component']
        when 'DROPDOWN', nil
          render_form_select(label: node['text'], name: node_name(node), options: options, required: node['required'])
        when 'RADIO_BUTTONS'
          render_form_radio_group(legend: node['text'], name: node_name(node), options: options, required: node['required'])
        else
          raise "component #{node['component']} not supported in #{node.inspect}"
        end
      end
    end

    def render_group_node(node)
      contents = node['item']&.map do |child|
        render_node(child)
      end
      case node['component']
      when 'INPUT_GROUP'
        render_form_group(node: node) do
          render_form_fieldset(legend: node['text']) do
            context.safe_join(contents, "\n")
          end
        end
      else
        render_section(title: node['text']) do |_section|
          context.safe_join(contents, "\n")
        end
      end
    end

    def render_form_group(node:, &block)
      return context.capture(&block) if parent_node && parent_node['component'] == 'INPUT_GROUP'

      context.render_form_group(needs_validation: node['required'], &block)
    end

    def render_dependent_item_wrapper(node, &block)
      if node['enable_behavior']
        conditions = node['enable_when']&.map do |condition|
          raise "only supports enable_when with 'question' and 'answer_code' (got: #{condition})" unless condition.key?('question') && condition.key?('answer_code')

          input_dependent_link_id = condition['question']
          input_name = link_id_to_node_name[input_dependent_link_id]
          raise "missing node name for dependency with link_id##{input_dependent_link_id}" unless input_name

          input_value = condition['answer_code']

          { input_name: input_name, input_value: input_value }
        end

        return context.render_dependent_block(conditions: conditions, &block)
      end

      return context.capture(&block)
    end

    def node_name(node)
      record_type = node.dig('mapping', 'record_type')
      processor_name = Hmis::Form::RecordType.find(record_type).processor_name if record_type

      custom_field_key = node.dig('mapping', 'custom_field_key')
      field_name = node.dig('mapping', 'field_name')

      # Join with period since that's the expected submission shape (Client.firstName)
      # If problematic we can use another separator and process accordingly in ConsumeExternalFormSubmissionsJob
      [processor_name, custom_field_key || field_name].compact.join('.')
    end

    # Map { linkd_id => name to use for input field }
    # Example: { 'client_first_name' => 'Client.firstName' }
    # Example: { 'link_id_1' => 'custom_field_key_x' }
    def link_id_to_node_name
      @link_id_to_node_name ||= form_definition.link_id_item_hash.map do |link_id, node|
        # Skip items without mapping. Note: the hash already excludes group items (see link_id_item_hash)
        next unless node['mapping']

        [link_id, node_name(node)]
      end.compact.to_h
    end

    def resolve_pick_list(node)
      pick_list_reference = node['pick_list_reference']
      pick_list_options = node['pick_list_options']

      if pick_list_reference
        # Try to resolve the pick_list_reference value from a GraphQL Enum.
        # This mirrors the logic of `localResolvePickList` on the HMIS Frontend. However, is not as comprehensive,
        # it only tries to match against a subset of Enums which are commonly referenced (HUD enums).
        found_enum = "Types::HmisSchema::Enums::Hud::#{pick_list_reference}".safe_constantize
        found_enum ||= "Types::HmisSchema::Enums::#{pick_list_reference}".safe_constantize # need for Race and Gender enums
        raise "Unable to resolve pick list reference: #{pick_list_reference}" unless found_enum

        found_enum.values.map do |k, v|
          # Use a regex to drop the id prefix if it exists: "(1) Yes" => "Yes"
          # (Pattern is pulled from the `generateEnumDescriptions` script on the HMIS front-end.)
          { value: k.to_s, label: v.description&.gsub(/^\([0-9A-Za-z]+\) /, '') || k.to_s }
        end
      elsif pick_list_options
        pick_list_options.map do |option|
          { value: option['code'], label: option['label'] || option['code'] }
        end
      end
    end
  end
end
