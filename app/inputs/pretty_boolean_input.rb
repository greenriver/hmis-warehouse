###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PrettyBooleanInput < SimpleForm::Inputs::BooleanInput
  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    checked = object.send(attribute_name)
    name = "#{object_name}[#{attribute_name}]"
    id = name.to_s.parameterize
    pre_label = template.content_tag(:span, '', class: 'c-checkbox__pre-label')
    if options[:pre_label].present?
      pre_label = template.content_tag(:span, options[:pre_label], class: 'c-checkbox__pre-label')
    end
    check =
      template.content_tag(:span, template.content_tag(:span, '', class: 'c-checkbox__check-icon'), class: 'c-checkbox__check-container')
    label_text_el = template.content_tag(:span, label_text)
    hint_text = template.content_tag(:span, options[:hint], class: 'c-checkbox__hint')
    label_and_hint = template.content_tag(:span, label_text_el + hint_text, class: 'c-checkbox__label')
    template.content_tag :div, class: 'c-checkbox' do
      build_hidden_field_for_checkbox +
      template.check_box_tag(name, 1, checked, merged_input_options.merge(id: id)) +
      template.content_tag(:label, pre_label + check + label_and_hint, for: id)
    end
  end

  def label

  end
end
