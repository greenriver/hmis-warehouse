###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PrettyBooleanGroupInput < SimpleForm::Inputs::CollectionRadioButtonsInput
  def input(wrapper_options = nil)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    radio_group = template.content_tag(:div) do
      current_value = object.send(attribute_name)
      collection.each do |label, value, _|
        name = "#{object_name}[#{attribute_name}]"
        if options[:multiple]
          checked = current_value.present? && value.in?(current_value)
          name += '[]'
          tag_name = :check_box_tag
        else
          checked = value == current_value
          tag_name = :radio_button_tag
        end
        id = name.to_s.parameterize + '_' + value.to_s
        if @builder.options[:wrapper] == :readonly
          internal = if checked
            template.content_tag :div, class: 'c-checkbox' do
              template.content_tag(:span, nil, label_html_options.merge(class: 'icon-checkmark o-color--positive mr-2')) +
              template.content_tag(:label, value, for: id)
            end
          else
            template.content_tag :div, class: 'c-checkbox' do
              template.content_tag(:span, nil, label_html_options.merge(class: 'icon-cross o-color--warning mr-2')) +
              template.content_tag(:label, value, for: id)
            end
          end
          template.concat(internal)
        else
          label_text_el = template.content_tag(:span, label, class: 'c-checkbox__label ml-6')
          checkbox_classes = ['c-checkbox']
          checkbox_classes << 'mb-2' if options[:multiple]
          checkbox_classes << 'c-checkbox--round' unless options[:multiple]
          template.concat(
            template.content_tag(:div, class: checkbox_classes) do
              template.send(tag_name, name, value, checked, merged_input_options.merge(id: id)) +
              template.content_tag(:label, label_text_el, for: id)
            end,
          )
        end
      end
    end
    radio_group
  end
end
