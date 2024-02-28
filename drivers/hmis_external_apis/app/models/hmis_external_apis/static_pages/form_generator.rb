
###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# render html from a from definition
module HmisExternalApis::StaticPages
  class FormGenerator
    attr_reader :context
    def initialize(context)
      @stack = []
      @context = context
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
      @stack.push(node)
      node_type = node['type']
      result = case node_type
      when 'STRING', 'DATE'
        render_input_node(node)
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
      @stack.pop
      return result
    end

    def parent_node
      @stack[-2]
    end

    def render_input_node(node)
      render_form_group do
        render_form_input(label: node['text'], name: node['link_id'], required: node['required'])
      end
    end

    def render_boolean_node(node)
      render_form_group do
        render_form_checkbox(label: node['text'], name: node['link_id'], required: node['required'])
      end
    end

    def render_numeric_node(node)
      render_form_group do
        render_numeric_input(label: node['text'], name: node['link_id'], required: node['required'])
      end
    end

    def render_text_node(node)
      render_form_group do
        render_form_textarea(label: node['text'], name: node['link_id'], required: node['required'])
      end
    end

    def render_display_node(node)
      context.tag.div(node['text'].html_safe)
    end

    def render_choice_node(node)
      raise "missing options in #{node.inspect} " unless node['pick_list_options']
      options = node['pick_list_options'].map do |option|
        {label: option['label'], value: option['code']}
      end
      render_form_group do
        case node['component']
        when 'DROPDOWN'
          render_form_select(label: node['text'], name: node['link_id'], options: options)
        when 'RADIO_BUTTONS'
          render_form_radio_group(legend: node['text'], name: node['link_id'], options: options)
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
        render_form_group do
          render_form_fieldset(legend: node['text']) do
            context.safe_join(contents, "\n")
          end
        end
      else
        render_section(title: node['text']) do |section|
          context.safe_join(contents, "\n")
        end
      end
    end

    def render_form_group(&block)
      return context.capture(&block) if parent_node && parent_node['component'] == 'INPUT_GROUP'

      context.render_form_group(&block)
    end
  end
end
