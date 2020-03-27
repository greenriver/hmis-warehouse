###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class BooleanButtonGroupInput < SimpleForm::Inputs::CollectionRadioButtonsInput
  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    button_group = template.content_tag(:div, class: 'o-boolean-button-group') do
      current_value = object.send(attribute_name)
      collection.each_with_index do |(label, value, _attrs), _index|
        checked = value == current_value
        name = "#{object_name}[#{attribute_name}]"
        id = name.to_s.parameterize + '_' + value.to_s
        template.concat(
          template.content_tag(:div, class: 'c-boolean-button c-boolean-button--round mb-1') do
            template.radio_button_tag(name, value, checked, merged_input_options.merge(id: id)) +
            template.content_tag(:label, label, for: id)
          end,
        )
      end
    end
    button_group
  end
end
