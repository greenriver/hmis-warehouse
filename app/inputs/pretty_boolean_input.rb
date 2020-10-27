###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PrettyBooleanInput < SimpleForm::Inputs::BooleanInput
  def input(wrapper_options = nil)
    checked = object.send(attribute_name)
    name = "#{object_name}[#{attribute_name}]"
    id = name.to_s.parameterize
    if @builder.options[:wrapper] == :readonly
      if checked
        template.content_tag :div, class: 'c-checkbox' do
          template.content_tag(:span, nil, label_html_options.merge(class: 'icon-checkmark o-color--positive mr-2')) +
          template.content_tag(:label, label_text, for: id)
        end
      else
        template.content_tag :div, class: 'c-checkbox' do
          template.content_tag(:span, nil, label_html_options.merge(class: 'icon-cross o-color--warning mr-2')) +
          template.content_tag(:label, label_text, for: id)
        end
      end
    else
      merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
      label_text_el = template.content_tag(:span, label_text)
      hint_text = template.content_tag(:span, options[:hint], class: 'c-checkbox__hint')
      label_and_hint = template.content_tag(:span, label_text_el + hint_text, class: 'c-checkbox__label')
      template.content_tag :div, class: 'c-checkbox' do
        template.check_box_tag(name, 1, checked, merged_input_options.merge(id: id)) +
        template.content_tag(:label, label_and_hint, for: id)
      end
    end
  end
end
