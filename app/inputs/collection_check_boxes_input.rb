class CollectionCheckBoxesInput < SimpleForm::Inputs::CollectionCheckBoxesInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly
      label_method = detect_collection_methods.first
      value_method = detect_collection_methods.last
      selected_value = object.send(attribute_name)
      selected_object = collection.select{|m| m.send(value_method).to_s == selected_value.to_s}
      value = selected_object.map{|m| m.send(label_method)}.first
      template.label_tag(nil, value, label_html_options)
    else
      super(wrapper_options)
    end
  end
end