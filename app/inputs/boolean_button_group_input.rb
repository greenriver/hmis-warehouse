###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BooleanButtonGroupInput < SimpleForm::Inputs::CollectionRadioButtonsInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly || input_options[:readonly] == true
      label_method = detect_collection_methods.first
      value_method = detect_collection_methods.last
      selected_value = if object.present?
        input_options[:selected].presence || object&.send(attribute_name)
      else
        input_options[:selected].presence
      end
      selected_object = collection.select { |m| m.send(value_method).to_s == selected_value.to_s }
      the_value = selected_object.map { |m| m.send(label_method) }.first
      existing_classes = label_html_options.try(:[], :class)
      existing_classes << 'd-block'
      existing_classes << 'readonly-value'
      template.label_tag('p', the_value, label_html_options.merge(class: existing_classes))
    else
      merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
      button_group = template.content_tag(:div, class: 'o-boolean-button-group') do
        current_value = if object.present?
          input_options[:selected].presence || object&.send(attribute_name)
        else
          input_options[:selected].presence
        end

        collection.each_with_index do |(label, value, _attrs), _index|
          checked = value.to_s == current_value.to_s
          name = "#{object_name}[#{attribute_name}]"
          id = (input_html_options[:id] || name.to_s.parameterize) + '_' + value.to_s
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
end
