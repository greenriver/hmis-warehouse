###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class CollectionCheckBoxesInput < SimpleForm::Inputs::CollectionCheckBoxesInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly
      label_method = detect_collection_methods.first
      value_method = detect_collection_methods.last
      selected_value = object.send(attribute_name)
      selected_object = collection.select { |m| m.send(value_method).to_s == selected_value.to_s }
      value = selected_object.map { |m| m.send(label_method) }.first
      existing_classes = label_html_options.try(:[], :class)
      existing_classes << 'd-block'
      existing_classes << 'readonly-value'
      template.label_tag(nil, value, label_html_options.merge(class: existing_classes))
    else
      super(wrapper_options)
    end
  end
end
