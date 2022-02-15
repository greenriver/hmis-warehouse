###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CollectionRadioButtonsInput < SimpleForm::Inputs::CollectionRadioButtonsInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly || input_options[:readonly] == true
      label_method = detect_collection_methods.first
      value_method = detect_collection_methods.last
      selected_value = object.send(attribute_name)
      selected_object = collection.select { |m| m.send(value_method).to_s == selected_value.to_s }
      value = selected_object.map { |m| m.send(label_method) }.first
      existing_classes = label_html_options.try(:[], :class)
      existing_classes << 'd-block'
      existing_classes << 'readonly-value'
      if value.present?
        template.label_tag('p', value, label_html_options.merge(class: existing_classes))
      else
        template.content_tag(:em, 'Blank', label_html_options)
      end

    else
      super(wrapper_options)
    end
  end
end
