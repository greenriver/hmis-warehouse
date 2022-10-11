###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PrettyBooleanInput < SimpleForm::Inputs::BooleanInput
  def input(wrapper_options = nil)
    checked = object.send(attribute_name)
    name = "#{object_name}[#{attribute_name}]"
    id = name.to_s.parameterize
    if @builder.options[:wrapper] == :readonly || input_options[:readonly] == true
      if checked
        style = '' # rubocop:disable Style/IdenticalConditionalBranches
        symbol_name = 'checkmark'
        wrapper_class = 'o-color--positive'
      else
        style = '' # rubocop:disable Style/IdenticalConditionalBranches
        symbol_name = 'cross'
        wrapper_class = 'o-color--warning'
      end
      template.content_tag :div, class: 'c-checkbox' do
        template.concat(svg_checkbox(template, wrapper_class, style, symbol_name))
        template.concat(template.content_tag(:label, label_text, for: id)) unless input_options[:label] == false
      end
    else
      merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
      label_text = input_options[:label] if input_options[:label].present?
      label_text = '' if input_options[:label] == false
      label_text_el = template.content_tag(:span, label_text)
      hint_text = template.content_tag(:span, options[:hint], class: 'c-checkbox__hint')
      label_and_hint = template.content_tag(:span, label_text_el + hint_text, class: 'c-checkbox__label')
      template.content_tag :div, class: 'c-checkbox' do
        build_hidden_field_for_checkbox +
        template.check_box_tag(name, 1, checked, merged_input_options.merge(id: id)) +
        template.content_tag(:label, label_and_hint, for: id)
      end
    end
  end

  private def svg_checkbox(template, wrapper_class, style, symbol_name)
    template.content_tag :span, class: "icon-svg--xs #{wrapper_class} mr-2" do
      template.content_tag :svg, style: style do
        template.content_tag(:use, '', 'xlink:href' => "\#icon-#{symbol_name}")
      end
    end
  end
end
